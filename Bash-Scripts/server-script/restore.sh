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
ORIGINALDIR=""
FILEDIR=""
DBNAME=""
DBUSER=""
DBPASS=""
URL=""
CURDIR=$PWD
FINAL=""
BKFILE=""
DBFILE=""
TEMPDIR=tempdirKK
WPCONFIG=""

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

function getInformation
{
        display "Collecting information for the job"
        read -p "Please, input backup original folder name: " ORIGINALDIR
        read -p "Please, input target directory (Blank for same as original): " FILEDIR
        read -p "Please, input target database name: " DBNAME
        read -p "Please, input target database username: " DBUSER
        read -p "Please, input target database password for '$DBUSER': " DBPASS
        read -p "Please, input new website URL with http/https: " URL
        FINAL=latest.$ORIGINALDIR.zip
        BKFILE=$ORIGINALDIR.zip
}

function checkvariables
{
        if [ -z $DBUSER ] || [ -z $DBUSER ] || [ -z $DBNAME ] || [ -z $URL ]
        then
                showresult "input error"
                exit 1
        fi

        if [ -z $FILEDIR ]
        then
                FILEDIR=$ORIGINALDIR
                showresult "Recover to the same directory '$ORIGINALDIR'"
        fi
        WPCONFIG=$FILELOC/$FILEDIR/wp-config.php

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
        showresult "Variables Checked"
}

function PrepareEnvironment
{
        if [ -e $FINAL ]
        then
                display "copying $FINAL to $FILELOC"
                cp $FINAL $FILELOC 
                cd $FILELOC
                display "Unpacking $FINAL ..."
                unzip -o $FINAL 2>> $ERRORFILE
                showresult "$FINAL unpacked."
        else    
                showresult "No Backup File '$FINAL' Found"
        fi
}

function RemoveExistedDirectory
{
        if [ -d "$FILELOC/$FILEDIR" ]
        then
                display "removing existing directory"
                rm -r $FILELOC/$FILEDIR
                showresult "$FILELOC/$FILEDIR found and removed" 
        fi
}

function RestoringFileDirectory
{
        display "Recover Directory from Backup"
        unzip -o $BKFILE -d $FILELOC/$TEMPDIR 2>>$ERRORFILE
        showresult "Recovered $BKFILE to $FILELOC/$TEMPDIR" 
        mv $FILELOC/$TEMPDIR/$ORIGINALDIR $FILELOC/$FILEDIR 2>>$ERRORFILE
        rm -r $FILELOC/$TEMPDIR 2>>$ERRORFILE
        chown -R nobody:nogroup $FILEDIR 2>>$ERRORFILE
        showresult "Modified folder permissions"
}


function configurewpconfig
{
        ORIGINALDB=$(cat $WPCONFIG | grep DB_NAME | cut -d \' -f 4) 2>> $ERRORFILE
        showresult "Original Database Name '$ORIGINALDB' retrieved"
        ORIGINALUSR=$(cat $WPCONFIG | grep DB_USER | cut -d \' -f 4) 2>>$ERRORFILE
        showresult "Original Database User '$ORIGINALUSR' retrieved"
        ORIGINALPASS=$(cat wp-config.php | grep DB_PASSWORD | cut -d \' -f 4) 2>>$ERRORFILE
        showresult "Original Database Password '$ORIGINALPASS' retrieved"
        DBFILE=$ORIGINALDB.sql

        if [ ! "$ORIGINALDB" == "$DBNAME" ]
        then
                sed -i "/DB_NAME/s/'[^']*'/'$DBNAME'/2" $WPCONFIG 2>>$ERRORFILE
                showresult "$WPCONFIG edited switch $ORIGINALDB to $DBNAME"
        fi
        if [ ! "$ORIGINALUSR" == "$DBUSER" ]
        then
                sed -i "/DB_USER/s/'[^']*'/'$DBUSER'/2" $WPCONFIG 2>>$ERRORFILE
                showresult "$WPCONFIG edited switch $ORIGINALUSR to $DBUSER"
        fi
        if [ ! "$ORIGINALPASS" == "$DBPASS" ]
        then
                sed -i "/DB_PASSWORD/s/'[^']*'/'$DBPASS'/2" $WPCONFIG
                showresult "$WPCONFIG edited switch $ORIGINALPASS to $DBPASS"
        fi
        DBFILE=$ORIGINALDB.sql
}

function CreateDBUser
{
        display "Create Database User"
        mysql -u root -e "CREATE USER $DBUSER IDENTIFIED BY '$DBPASS';" 2>>$ERRORFILE
        showresult "Created Database User $DBUSER"
}

function DropDatabase
{
        display "droping $DBNAME database"
        mysql -u root -e "DROP DATABASE $DBNAME;" 2>> $ERRORFILE
        showresult "Droped $DBNAME" 
}



function createDatabase
{
        display "create database $DBNAME"
        mysql -u root -e "CREATE DATABASE $DBNAME;" 2>>$ERRORFILE
        mysql -u root -e "GRANT ALL PRIVILEGES ON $DBNAME.* TO $DBUSER;" 2>>$ERRORFILE
        showresult "Created Database $DBNAME and gave Privileges to $DBUSER."
}

function ImportDatabase
{
        display "importing database from $DBFILE"
        mysql -u $DBUSER --password="$DBPASS" $DBNAME < $DBFILE 2>>$ERRORFILE
        showresult "Imported $DBFILE to database $DBNAME"
}

function RemoveFiles
{
        showresult "Moved $FILELOC/$TEMPDIR to $FILELOC/$FILEDIR" 
        rm $BKFILE $DBFILE $FINAL 2>>$ERRORFILE
        showresult "Removed unnessary files $BKFILE $DBFILE $FINAL"
}

function UpdateURL
{
        display "Modifying HomeURL and SiteURL"
        TABLEPREF=$(cat $WPCONFIG | grep "\$table_prefix" | cut -d \' -f 2) 2>>$ERRORFILE
        showresult "Table prefix '$TABLEPREF' retrieved"
        DBCOMMAND="UPDATE ${TABLEPREF}options SET option_value = '$URL' WHERE option_id =1 OR option_id=2;"
        SELECTCOMMAND="SELECT * FROM ${TABLEPREF}options WHERE option_id=1 OR option_id=2;"
        mysql -u $DBUSER --password="$DBPASS" $DBNAME -e "$DBCOMMAND" 2>>$ERRORFILE
        showresult "Updated homeurl/siteURL to $URL."
        echo "homeurl and siteurl in table ${TABLEPREF}options is shown below"
        mysql -u $DBUSER --password="$DBPASS" $DBNAME -e "$SELECTCOMMAND"
        mysql -u $DBUSER --password="$DBPASS" $DBNAME -e "$SELECTCOMMAND" >> $RESULTFILE
}

function discourageSearchEnging
{
    wp option set blog_public 0 --allow-root 2>> $ERRORFILE
    showresult "Discouraged search engines from indexing the site"
}

function disablePlugins
{
    
    while true;
    do
        echo
        echo " List Plugins and status "
        sudo wp plugin list --allow-root
        echo
        read -p "(Type 'DONE' to exit) Type plugin name to disable: " PLUGIN
        if [ "$PLUGIN" == "DONE" ]
        then
                break
        else
                wp plugin deactivate $PLUGIN --allow-root 2>> $ERRORFILE
        fi
    done
}

function updatePlugins
{
    while true;
    do
        echo
        echo " List Plugins and status "
        sudo wp plugin list --allow-root
        echo
        read -p "Type 'DONE' to exit, Type 'ALL' update all plugins, or type plugin name to Update: " PLUGIN
        if [ "$PLUGIN" == "DONE" ]
        then
                break
        elif  [ "$PLUGIN" == "ALL" ]
        then
                wp plugin update --all --allow-root 2>> $ERRORFILE
        else
                wp plugin update $PLUGIN --allow-root 2>> $ERRORFILE
        fi
    done

}

function ConfigureTestSite
{
        while true;
        do
                read -p "Is this a test site? (Y/N): " YN
                case $YN in
                        [yY]|[yY][eE][sS])
                                cd $FILELOC/$FILEDIR
                                discourageSearchEnging
                                disablePlugins
                                updatePlugins
                                wp plugin status --allow-root
                                break
                                ;;
                        [nN]|[nN][oO])
                                break
                                ;;
                        *)
                                echo "Please answer yes or no"
                                ;;
                esac
        done

}
 
function completeURLChanged
{
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
                                        echo "working .."
                                        sudo -u root wp search-replace $ORIGINALURL $URL --all-tables --allow-root 2>>$ERRORFILE
                                        showresult "Searched and replaced URL in database $ORIGINALURL to $URL" 
                                        pauseandclear
                                        ConfigureTestSite
                                        
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
}



function Finalize
{
        cd $CURDIR
        showresult " ----==== ALL DONE ====----" 
        cat $RESULTFILE
}

clear
getInformation
checkvariables
pauseandclear
PrepareEnvironment
RemoveExistedDirectory
pauseandclear
RestoringFileDirectory
pauseandclear
configurewpconfig
pauseandclear
CreateDBUser
#pauseandclear
DropDatabase
#pauseandclear
createDatabase
#pauseandclear
ImportDatabase
RemoveFiles
pauseandclear
UpdateURL
pauseandclear
completeURLChanged
Finalize