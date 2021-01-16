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
read -p "Please input the website File Directory: " FILEDIR
read -p "Please input the website database name: " DBNAME
RESULTFILE="result.txt"
ERRORFILE="error.txt"

echo " ----==== RESULT INFORMATION ====----" > $RESULTFILE

function display
{
    HLINE="********************************************************************************"
    EMPTYLINE="*                                                                              *"
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
    HLINE="********************************************************************************"
    echo $HLINE
    echo "*               $1                   "
    echo $HLINE
    echo 
    echo $1 >> $RESULTFILE
}

function pauseandclear
{
        read -p "Press ENTER to continue" ENTER
        clear
}


if [ -z $FILEDIR ] || [ -z $DBNAME ]
then
        echo "Input Missing"
        exit 1
fi

if [ -d "$FILELOC/$FILEDIR" ]
then
        while true;
        do
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

while true;
do
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
clear
showresult " ----==== ALL DONE ====----" 
cat $RESULTFILE
