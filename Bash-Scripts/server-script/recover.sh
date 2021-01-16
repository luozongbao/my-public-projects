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
RESULTFILE="result.txt"

echo " ----==== RESULT INFORMATION ====----" > $RESULTFILE



clear

if [ -z $DBUSER ] || [ -z $FILEDIR ] || [ -z $DBUSER ] || [ -z $DBNAME ] || [ -z $ORIGINALDB ] || [ -z $URL ]
then
        echo "input error"
        exit 1
fi

if [ -f $FINAL ]
then
        echo "Original Backup $FINAL Found"
else
        echo "Original backup $FINAL not found"
        exit 1
fi

if [ -d $FILELOC ]
then
        echo "$FILELOC Found"
else
        echo "File Location $FILELOC error"
        exit 1
fi
echo "Variables Checked"
read -p "Press Enter to continue: " ENTER
echo "START NEW JOB" #>> error.txt
echo "Moving file to $FILELOC"
cp $FINAL $FILELOC #>> error.txt
cd $FILELOC
echo "Unpacking $FINAL ..."
unzip $FINAL #1>unzipresult.txt 2>> error.txt
if [ -d "$FILELOC/$FILEDIR" ]
then
        echo "removing existing directory"
        rm -r $FILELOC/$FILEDIR
        echo "$FILELOC/$FILEDIR found and removed" >> $RESULTFILE
fi
echo "droping $DBNAME database"
#mysqladmin -u $DBUSER --password="$DBPASS" drop $DBNAME #>> error.txt
mysql -u root -e "DROP DATABASE $DBNAME;"
echo "Droped $DBNAME" >> $RESULTFILE
echo "create database $DBNAME"
#mysqladmin -u $DBUSER --password="$DBPASS" create $DBNAME #>> error.txt
mysql -u root -e "CREATE DATABASE $DBNAME;"
mysql -u root -e "GRANT ALL PRIVILEGES ON $DBNAME.* TO $DBUSER;"
echo "Created Database $DBNAME and gave Privileges to $DBUSER." >> $RESULTFILE
echo "importing database from $DBFILE"
mysql -u $DBUSER --password="$DBPASS" $DBNAME < $DBFILE #>> error.txt
echo "Imported $DBFILE to $DBNAME" >> $RESULTFILE
echo "Database recovered"
echo "Start restoring files to $FILEDIR"
read -p "Press Enter to continue" ENTER
clear
unzip $BKFILE -d $FILELOC/$TEMPDIR #1>unzipresult.txt  2 >> error.txt
echo "Recovered $BKFILE to $FILELOC/$TEMPDIR" >> $RESULTFILE
clear
mv $FILELOC/$TEMPDIR/$ORIGINALDIR $FILELOC/$FILEDIR
rm -r $FILELOC/$TEMPDIR
echo "Moved $FILELOC/$TEMPDIR to $FILELOC/$FILEDIR" >> $RESULTFILE
rm $BKFILE $DBFILE $FINAL
echo "Removed unnessary files" >> $RESULTFILE
echo "Unnessary files removed"
chown -R nobody:nogroup $FILEDIR #>> error.txt
echo "Modified folder permissions"
echo "Set permission to $FILEDIR" >> $RESULTFILE
cd $CURDIR
read -p "Press Enter to continue: " ENTER
while true;
do
        clear
        echo "NOTE: "
        echo    "1. Please, look up the file for Table for the next step"
        echo    "2. Please, make sure the database name is set correctly"
        echo
        read -p "Do you want to edit wp-config.php now (Y/N)" YN
        case $YN in
                [yY]|[yY][eE][sS])
                        vim $FILELOC/$FILEDIR/wp-config.php #2>> error.txt
                        echo "Edited $FILELOC/$FILEDIR/wp-config.php" >> $RESULTFILE
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
echo "Modifying HomeURL and SiteURL"
read -p "Please input Table Prefix: " TABLEPREF
DBCOMMAND="UPDATE ${TABLEPREF}options SET option_value = '$URL' WHERE option_id =1 OR option_id=2;"
SELECTDB="SELECT * FROM ${TABLEPREF}options WHERE option_id=1 OR option_id=2;"
echo "please enter $DBUSER password"
mysql -u $DBUSER --password="$DBPASS" $DBNAME -e "$DBCOMMAND" #>> error.txt
echo "UPDATE homeurl/siteURL to $URL." >> $RESULTFILE
echo "update file and database done."
echo "Modified Result as below:"
mysql -u $DBUSER --password="$DBPASS" $DBNAME -e "$SELECTDB" >> $RESULTFILE
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
                                sudo -u root wp search-replace $ORIGINALURL $URL --all-tables --allow-root
                                cd $CURDIR
                                echo "Search and replace URL in database $ORIGINALURL to $URL" >> $RESULTFILE
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
echo " ----==== ALL DONE ====----" >> $RESULTFILE
echo "============ RESULT ============"
cat $RESULTFILE


