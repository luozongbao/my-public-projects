#! /bin/bash
###################################################################
# Script Name	: Remove Website                                                                                             
# Description	: Used to Remove website on server                                                                      
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
CURDIR=$PWD
FILEDIR=""
DBNAME=""
DBUSER=""
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
        display "Collect Information For Website Removal"
        read -p "Please input the website File Directory: " FILEDIR
	WPCONFIG=$FILELOC/$FILEDIR/wp-config.php
        if [ -e $WPCONFIG ]
        then
                DBNAME=$(cat $WPCONFIG | grep DB_NAME | cut -d \' -f 4) 2>>$ERRORFILE
                DBUSER=$(cat $WPCONFIG | grep DB_USER | cut -d \' -f 4) 2>>$ERRORFILE
        else
                showresult "$FILELOC/$FILEDIR is an invalid Wordpress Folder"
                exit 1
        fi
}

function checkvariables
{
        if [ -z $FILEDIR ] || [ -z $DBNAME ]
        then
                echo "Input Missing"
                exit 1
        fi
}

function RemoveFiles
{
        if [ -d "$FILELOC/$FILEDIR" ]
        then
                while true;
                do
                        display "Remove File Folder"
                        echo "This will remove directory $FILELOC/$FILEDIR and files within it permanently"
                        read -p " Continue (Y/N): " YN
                        case $YN in
                                [yY]|[yY][eE][sS])
                                        rm -r $FILELOC/$FILEDIR 2>> $ERRORFILE
                                        showresult "$FILELOC/$FILEDIR removed."
                                        break
                                        ;;
                                [nN]|[nN][oO])
                                        showresult "skipped removing $FILELOC/$FILEDIR"
                                        break
                                        ;;
                                *)
                                        echo "Please answer Y/N"
                                        ;;
                        esac
                done
        else
                showresult "DIrectory $FILELOC/$FILEDIR not found."
                exit 1
        fi
}

function RemoveDatabase
{
        while true;
        do
                display "Remove Database"
                read -p "This will remove database $DBNAME permanently (Y/N): " YN
                case $YN in
                        [yY]|[yY][eE][sS])
                                mysql -u root -e "DROP DATABASE $DBNAME;" 2>> $ERRORFILE
                                showresult "$DBNAME removed"
                                break
                                ;;
                        [nN]|[nN][oO])
                                showresult "skipping remove database $DBNAME"
                                break
                                ;;
                        *)
                                echo "Please answer Y/N"
                                ;;
                esac
        done
}

function RemoveDatabaseUser
{
        while true;
        do
                display "Remove Database User"
                echo "Your Database User might be used with other database.  "
                read -p "Do you want to remove database user $DBUSER (Y/N): " YN
                case $YN in
                        [yY]|[yY][eE][sS])
                                mysql -u root -e "DROP USER $DBUSER;" 2>> $ERRORFILE
                                showresult "Database User $DBUSER removed"
                                break
                                ;;
                        [nN]|[nN][oO])
                                showresult "skipping remove database user $DBUSER"
                                break
                                ;;
                        *)
                                echo "Please answer Y/N"
                                ;;
                esac
        done
}

function Finalize
{
        showresult " ----==== ALL DONE ====----" 
        cat $RESULTFILE
}

clear
getInformation
checkvariables
RemoveFiles
pauseandclear
RemoveDatabase
pauseandclear
RemoveDatabaseUser
Finalize