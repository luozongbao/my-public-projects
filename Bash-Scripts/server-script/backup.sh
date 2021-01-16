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
ERRFILE=error.txt

echo " ----==== RESULT INFORMATION ====----" > $RESULTFILE

clear
# CHCEK VALID VARIABLES
if [ -d "$DIRLOC" ];
then
	echo "Directory $DIRLOC CHECKED"
	echo "Directory $DIRLOC CHECKED" >> $RESULTFILE
else
	echo "$DIRLOC WRONG FILE DIRECTORY LOCATION" #>> $ERRFILE
	exit 1
fi

if [ -z "$FILEDIR" ];
then
	echo "Files Directory INPUT IS EMPTY" #>> $ERRFILE
	exit 1
else
	if [ -d "$DIRLOC/$FILEDIR" ];
	then
		echo "FILE DIRECTORY $DIRLOC/$FILEDIR CHECKED"
		echo "File Directory $DIRLOC/$FILEDIR CHECKED" >> $RESULTFILE
	else
		echo "WRONG FILE DIRECTORY $DIRLOC/$FILEDIR" # >> $ERRFILE
		exit 1
	fi
fi

if [ -z $DBNAME ];
then
	echo "Database Name INPUT IS EMPTY" #>> $ERRFILE
	exit 1
else
	echo "Database Name $DBNAME VARIABLE CHECKED"
	echo "Database Name: $DBNAME " >> $RESULTFILE
fi

if [ -z $DBUSER ];
then
	echo "Database User INPUT IS EMPTY" #>> $ERRFILE
	exit 1
else
	echo "Database User VARIABLE CHECKED"
	echo "Database USER: $DBUSER" >> $RESULTFILE
fi
#ENTER TO CONTINUE
read -p "File Check Done" ENTER
clear
echo "Start Backing up $DIRLOC/$FILEDIR Files"
echo
# ENTER TO CONTINUE
read -p "Enter to continue" ENTER

# BACKUP FINAL FILE
if [ -e $FINAL ];
then
	mv $FINAL $BKFINAL
	echo "Backed up previous backup file $FINAL to $BKFINAL"
	echo "Backed up previous backup file $FINAL to $BKFINAL" >> $RESULTFILE
fi

# ARCHIVING DIRECTORY
cd $DIRLOC
zip -r $BKFILE $FILEDIR
clear
echo "$DIRLOC/$FILEDIR Archived"
echo "$DIRLOC/$FILEDIR Archived" >> $RESULTFILE
# MOVE ARCHIVED FILE TO CURRENT DIRECTORY
mv $BKFILE $CURDIR
cd $CURDIR
echo
echo "Dumping Database $DBNAME to $DBFILE"
echo "Dumping Database $DBNAME to $DBFILE" >> $RESULTFILE
echo
echo "mysql password for user $DBUSER"
# EXPORT DATABASE
mysqldump -u $DBUSER --pass="$DBPASS" $DBNAME > $DBFILE
clear
echo "Database exported to $DBFILE"
echo "Database exported to $DBFILE" >> $RESULTFILE
echo
echo "Archiving ... "
echo
# ARCHIVE BACKUP FILES
zip $FINAL $BKFILE $DBFILE
echo "Archive $BKFILE and $DBFILE to $FINAL"
echo "Archive $BKFILE and $DBFILE to $FINAL" >> $RESULTFILE
echo
while true;
do
	read -p "Removed unnessessary files?" YN
	case $YN in [yY]|[yY][eE][sS])
		#REMOVE ARCHIVED FILES
		echo "removing unnessessary files..."
		rm $DBFILE
		rm $BKFILE
		echo "Removed $BKFILE and $DBFILE" >> $RESULTFILE
		echo "Removed $BKFILE and $DBFILE"
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
echo " ----==== ALL DONE ====----" >> $RESULTFILE
echo "ALL DONE"
cat $RESULTFILE




