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

FILELOC=/usr/local/lsws/sites
FILEDIR=""
DBNAME=""
# DBUSER=""
# DBPASS=""
CURDIR=$PWD
FINAL=""
DBFILE=""
BKFILE=""
BKFINAL=""
WPCONFIG=""


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
	display "Collect Information for backup"
	read -p "Please input files directory:" FILEDIR
	WPCONFIG=$FILELOC/$FILEDIR/wp-config.php
	DBNAME=$(cat $WPCONFIG | grep DB_NAME | cut -d \' -f 4) 2>>$ERRORFILE
	showresult "Retrieved Database Name '$DBNAME' from $WPCONFIG"
	FINAL=latest.$FILEDIR.zip
	DBFILE=$DBNAME.sql
	BKFILE=$FILEDIR.zip
	BKFINAL=old.$FILEDIR.zip
}

# CHCEK VALID VARIABLES
function checkvariables
{
	if [ -d "$FILELOC" ];
	then
		display "Directory $FILELOC CHECKED"
		echo "Directory $FILELOC CHECKED" >> $RESULTFILE
	else
		display "$FILELOC WRONG FILE DIRECTORY LOCATION"
		exit 1
	fi

	if [ -z "$FILEDIR" ];
	then
		display "Files Directory INPUT IS EMPTY" 
		echo "Files Directory INPUT IS EMPTY" >> $RESULTFILE
		exit 1
	else
		if [ -d "$FILELOC/$FILEDIR" ];
		then
			display "FILE DIRECTORY $FILELOC/$FILEDIR CHECKED"
		else
			display "WRONG FILE DIRECTORY $FILELOC/$FILEDIR"
			exit 1
		fi
	fi

	display "Input Information CHECKED.  Start Backing up $FILELOC/$FILEDIR Files"
}

function backupbackup
{
	# BACKUP FINAL FILE
	if [ -e $FINAL ];
	then
		pauseandclear
		display "Found Previous Backup File '$FINAL'"
		mv $FINAL $BKFINAL
		showresult "Backed up previous backup file $FINAL to $BKFINAL"
	fi
}

# ARCHIVING DIRECTORY
function ArchiveDirectory
{
	cd $FILELOC
	zip -r $BKFILE $FILEDIR 2>>$ERRORFILE
	clear
	mv $BKFILE $CURDIR 2>>$ERRORFILE
	cd $CURDIR
	showresult "$FILELOC/$FILEDIR Archived"
}
# MOVE ARCHIVED FILE TO CURRENT DIRECTORY

# EXPORT DATABASE
function exportDatabase
{
	display "Dumping Database $DBNAME to $DBFILE"
	# mysqldump -u $DBUSER --password="$DBPASS" $DBNAME > $DBFILE 2>>$ERRORFILE
	mysqldump -u root $DBNAME > $DBFILE 2>>$ERRORFILE
	showresult "Database exported to $DBFILE"
}

# ARCHIVE BACKUP FILES
function ArchiveBackupFiles
{
	display "Archiving files..."
	zip $FINAL $BKFILE $DBFILE 2>>$ERRORFILE
	showresult "Archived $BKFILE and $DBFILE to $FINAL"
}

function RemoveUnecessaryFiles
{
	while true;
	do
		display "Unnecessary Files"
		read -p "Remove unecessary files? (Y/N)" YN
		case $YN in [yY]|[yY][eE][sS])
			#REMOVE ARCHIVED FILES
			echo "removing unnecessary files..."
			rm $DBFILE
			rm $BKFILE
			showresult "Removed $BKFILE and $DBFILE"
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
backupbackup
pauseandclear
ArchiveDirectory
pauseandclear
exportDatabase
pauseandclear
ArchiveBackupFiles
pauseandclear
RemoveUnecessaryFiles
pauseandclear
Finalize




