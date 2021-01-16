#! /bin/bash
###################################################################
# Script Name	: Backup Website                                                                                             
# Description	: To backup a website on server                                                                      
# Args         	:                       
# Date          :
# Version       :                                                                                           
# Author       	: Atipat Lorwongam                                           
# Email        	: asecondsun@outlook.com                               
###################################################################
if (( $EUID != 0 )); then
	echo "Please run as root"
	exit
fi

DIRLOC=/usr/local/lsws/sites
read -p "Please input files directory:" FILEDIR
read -p "Please input database name:" DBNAME
read -p "please input database user:" DBUSER
read -p "Please input database password for '$DBUSER': " DBPASS
CURDIR=$PWD
FINAL=latest.$FILEDIR.zip
DBFILE=$DBNAME.sql
BKFILE=$FILEDIR.zip
BKFINAL=old.$FILEDIR.zip


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

echo " ----==== RESULT INFORMATION ====----" > $RESULTFILE

clear
# CHCEK VALID VARIABLES
if [ -d "$DIRLOC" ];
then
	display "Directory $DIRLOC CHECKED"
	echo "Directory $DIRLOC CHECKED" >> $RESULTFILE
else
	display "$DIRLOC WRONG FILE DIRECTORY LOCATION"
	exit 1
fi

if [ -z "$FILEDIR" ];
then
	display "Files Directory INPUT IS EMPTY" 
	echo "Files Directory INPUT IS EMPTY" >> $RESULTFILE
	exit 1
else
	if [ -d "$DIRLOC/$FILEDIR" ];
	then
		display "FILE DIRECTORY $DIRLOC/$FILEDIR CHECKED"
	else
		display "WRONG FILE DIRECTORY $DIRLOC/$FILEDIR"
		exit 1
	fi
fi

if [ -z $DBNAME ];
then
	display "Database Name INPUT IS EMPTY"
	exit 1
else
	display "Database Name $DBNAME VARIABLE CHECKED"
fi

if [ -z $DBUSER ];
then
	display "Database User INPUT IS EMPTY" 
	exit 1
else
	display "Database User $DBUSER CHECKED"
fi
#ENTER TO CONTINUE
clear
display "Input Information CHECKED.  Start Backing up $DIRLOC/$FILEDIR Files"
# ENTER TO CONTINUE
read -p "Enter to continue" ENTER

# BACKUP FINAL FILE
if [ -e $FINAL ];
then
	display "Found Previous Backup File '$FINAL'"
	mv $FINAL $BKFINAL
	display "Backed up previous backup file $FINAL to $BKFINAL"
fi

# ARCHIVING DIRECTORY
cd $DIRLOC
zip -r $BKFILE $FILEDIR 2>>$ERRORFILE
clear
showresult "$DIRLOC/$FILEDIR Archived"
# MOVE ARCHIVED FILE TO CURRENT DIRECTORY
mv $BKFILE $CURDIR 2>>$ERRORFILE
cd $CURDIR
pauseandclear
display "Dumping Database $DBNAME to $DBFILE"
# EXPORT DATABASE
mysqldump -u $DBUSER --pass="$DBPASS" $DBNAME > $DBFILE 2>>$ERRORFILE
showresult "Database exported to $DBFILE"
pauseandclear
display "Archiving files..."
# ARCHIVE BACKUP FILES
zip $FINAL $BKFILE $DBFILE 2>>$ERRORFILE
showresult "Archived $BKFILE and $DBFILE to $FINAL"
pauseandclear
while true;
do
	display "Unnecessary Files"
	read -p "Removed unnecessary files?" YN
	case $YN in [yY]|[yY][eE][sS])
		#REMOVE ARCHIVED FILES
		echo "removing unnecessary files..."
		rm $DBFILE
		rm $BKFILE
		showresult "Removed $BKFILE and $DBFILE"
		pauseandclear
		break
		;;
	[nN]|[nN][oO])
		break
		;;
	*)
		echo "Please answer Yes/No"
		;;
esac
done	
echo
showresult " ----==== ALL DONE ====----" 
echo "ALL DONE"
cat $RESULTFILE




