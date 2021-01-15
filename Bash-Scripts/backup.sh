#! /bin/bash
if (( $EUID != 0 )); then
	echo "Please run as root"
	exit
fi
read -p "Please input files directory:" FILEDIR
read -p "Please input database name:" DBNAME
read -p "please input database user:" DBUSER
read -p "Please input database password for '$DBUSER': " DBPASS
CURDIR=$PWD
DIRLOC=/usr/local/lsws/sites
FINAL=latest.$FILEDIR.zip
DBFILE=$DBNAME.sql
BKFILE=$FILEDIR.zip
BKFINAL=old.$FILEDIR.zip
ERRFILE=error.txt

clear
# CHCEK VALID VARIABLES
if [ -d "$DIRLOC" ];
then
	echo "DREICT $DIRLOC CHECKED"
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
	echo "Database Name VARIABLE CHECKED"
fi

if [ -z $DBUSER ];
then
	echo "Database User INPUT IS EMPTY" #>> $ERRFILE
	exit 1
else
	echo "Database User VARIABLE CHECKED"
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
	echo "Backed up file $FINAL to $BKFINAL"
fi

# ARCHIVING DIRECTORY
cd $DIRLOC
zip -r $BKFILE $FILEDIR
clear
echo "$DIRLOC/$FILEDIR Archived"
# MOVE ARCHIVED FILE TO CURRENT DIRECTORY
mv $BKFILE $CURDIR
cd $CURDIR
echo
echo "Dumping Database $DBNAME to $DBFILE"
echo
echo "mysql password for user $DBUSER"
# EXPORT DATABASE
mysqldump -u $DBUSER --pass="$DBPASS" $DBNAME > $DBFILE
clear
echo "Database exported to $DBFILE"
echo
echo "Archiving ... "
echo
# ARCHIVE BACKUP FILES
zip $FINAL $BKFILE $DBFILE
echo
while true;
do
	read -p "Removed unnessessary files?" YN
	case $YN in [yY]|[yY][eE][sS])
		#REMOVE ARCHIVED FILES
		echo "removing unnessessary files..."
		rm $DBFILE
		rm $BKFILE
		echo "file removed."
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
echo "ALL DONE"


