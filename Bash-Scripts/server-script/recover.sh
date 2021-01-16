#! /bin/bash
###################################################################
# Script Name	: Recover website from backup file                                                                                             
# Description	: to be run on wordpress server to recover website                                                                      
# Args         	:                       
# Date          :
# Version       :                                                                                            
# Author       	: Atipat Lorwongam                                           
# Email         : asecondsun@outlook.com                               
###################################################################
if (( $EUID != 0 )); then
    echo "Please run as root"
    exit
fi

FILELOC=/usr/local/lsws/sites
read -p "Please, input original backup folder name: " ORIGINALDIR
read -p "Please, input target directory: " FILEDIR
read -p "Please, input original database name: " ORIGINALDB
read -p "Please, input target database name: " DBNAME
read -p "Please, input database username: " DBUSER
read -p "Please, input database password for '$DBUSER': " DBPASS
read -p "Please, input new website URL with http/https: " URL

CURDIR=$PWD
FINAL=latest.$ORIGINALDIR.zip
BKFILE=$ORIGINALDIR.zip
DBFILE=$ORIGINALDB.sql
TEMPDIR=tempdirKK
WPCONFIG=$FILELOC/$FILEDIR/wp-config.php

RESULTFILE="$CURDIR/result.txt"
ERRORFILE="$CURDIR/error.txt"

echo " ----==== RESULT INFORMATION ====----" > $RESULTFILE

function display
{
    HLINE="****************************************************************************************************"
    EMPTYLINE="*                                                                                                  *"
    echo "$HLINE"
    echo "$EMPTYLINE"
    echo "$EMPTYLINE"
    echo "*               $1                   "
    echo "$EMPTYLINE"
    echo "$EMPTYLINE"
    echo "$HLINE"
    echo
}

function showresult
{
    HLINE="****************************************************************************************************"
    echo "$HLINE"
    echo "*               $1                   "
    echo "$HLINE"
    echo 
    echo $1 >> $RESULTFILE
}

function pauseandclear
{
        read -p "Press ENTER to continue" ENTER
        clear
}


clear

if [ -z $DBUSER ] || [ -z $FILEDIR ] || [ -z $DBUSER ] || [ -z $DBNAME ] || [ -z $ORIGINALDB ] || [ -z $URL ]
then
        showresult "input error"
        exit 1
fi

if [ -f $FINAL ]
then
        showresult "Original Backup $FINAL Found"
else
        showresult "Original backup $FINAL not found"
        exit 1
fi

if [ -d $FILELOC ]
then
        showresult "$FILELOC Found"
else
        showresult "File Location $FILELOC error"
        exit 1
fi
clear
display "Variables Checked"
pauseandclear

display "Moving file to $FILELOC"
cp $FINAL $FILELOC 
cd $FILELOC
display "Unpacking $FINAL ..."
unzip $FINAL 2>> $ERRORFILE
if [ -d "$FILELOC/$FILEDIR" ]
then
        display "removing existing directory"
        rm -r $FILELOC/$FILEDIR
        showresult "$FILELOC/$FILEDIR found and removed" 
        pauseandclear
fi
display "droping $DBNAME database"
mysql -u root -e "DROP DATABASE $DBNAME;" 2>> $ERRORFILE
showresult "Droped $DBNAME" 
pauseandclear

display "create database $DBNAME"
mysql -u root -e "CREATE DATABASE $DBNAME;" 2>>$ERRORFILE
mysql -u root -e "GRANT ALL PRIVILEGES ON $DBNAME.* TO $DBUSER;" 2>>$ERRORFILE
showresult "Created Database $DBNAME and gave Privileges to $DBUSER."
pauseandclear

display "importing database from $DBFILE"
mysql -u $DBUSER --password="$DBPASS" $DBNAME < $DBFILE 2>>$ERRORFILE
showresult "Imported $DBFILE to $DBNAME"
display "Database recovered"
display "Start restoring files to $FILEDIR"
pauseandclear

unzip $BKFILE -d $FILELOC/$TEMPDIR 2>>$ERRORFILE
showresult "Recovered $BKFILE to $FILELOC/$TEMPDIR" 
pauseandclear

mv $FILELOC/$TEMPDIR/$ORIGINALDIR $FILELOC/$FILEDIR 2>>$ERRORFILE
rm -r $FILELOC/$TEMPDIR 2>>$ERRORFILE
showresult "Moved $FILELOC/$TEMPDIR to $FILELOC/$FILEDIR" 
rm $BKFILE $DBFILE $FINAL 2>>$ERRORFILE
showresult "Removed unnessary files" 
display "Modifying Folder Permission"
chown -R nobody:nogroup $FILEDIR 2>>$ERRORFILE
showresult "Modified folder permissions"
cd $CURDIR
pauseandclear

if [ ! "$ORIGINALDB" == "$DBNAME" ]
then
        display "Edited $WPCONFIG and configure Database"
        sed -i 's/$ORIGINALDB/DBNAME/g"' $WPCONFIG 2>>$ERRORFILE
        showresult "$WPCONFIG edited switch $ORIGINALDB to $DBNAME"
fi

display "Modifying HomeURL and SiteURL"
TABLEPREF=$(cat $WPCONFIG "\$table_prefix" | cut -d \' -f 2) 2>>$ERRORFILE
showresult "Table prefix '$TABLEPREF' retrieved"
DBCOMMAND="UPDATE ${TABLEPREF}options SET option_value = '$URL' WHERE option_id =1 OR option_id=2;"
SELECTCOMMAND="SELECT * FROM ${TABLEPREF}options WHERE option_id=1 OR option_id=2;"
mysql -u $DBUSER --password="$DBPASS" $DBNAME -e "$DBCOMMAND" 2>>$ERRORFILE
showresult "Updated homeurl/siteURL to $URL." 
echo "update file and database done."
echo "Modified Result as below:"
mysql -u $DBUSER --password="$DBPASS" $DBNAME -e "$SELECTCOMMAND"
mysql -u $DBUSER --password="$DBPASS" $DBNAME -e "$SELECTCOMMAND" >> $RESULTFILE
pauseandclear

if [ ! "$FILEDIR" == "$ORIGINALDIR" ] || [ ! "$ORIGINALDB" == "$DBNAME" ]
then
        echo "Moving Site or Relocate Site detected"
        while true;
        do
                read -p "Do you want to update the site URL? (Y/N): " YN
                case $YN in
                        [yY]|[yY][eE][sS])
                                cd $FILELOC/$FILEDIR
                                echo "*** THIS IS IMPORTANT DO NOT MISS TYPED ***"
                                echo "*** Please check and recheck before press ENTER" 
                                read -p "Please input your original website url with http/https: " ORIGINALURL
                                sudo -u root wp search-replace $ORIGINALURL $URL --all-tables --allow-root 2>>$ERRORFILE
                                cd $CURDIR
                                showresult "Searched and replaced URL in database $ORIGINALURL to $URL" 
                                pauseandclear
                                break
                                ;;
                        [nN]|[nN][oO])
                                break
                                ;;
                        *)
                                echo "please answer yes or no"
                                ;;
                esac
        done
fi
showresult " ----==== ALL DONE ====----" 
cat $RESULTFILE


