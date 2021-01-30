#! /bin/bash
###################################################################
# Script Name	: Backup Website                                                                                             
# Description	: Script to set new server                                                                 
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
ORIGINALDIR=""
FILEDIR=""
DBNAME=""
DBUSER=""
DBPASS=""
URL=""
CURDIR=$PWD
FINAL=""
DBFILE=""
TEMPDIR=tempdirKK
BKFILE=""
BKFINAL=""
WPCONFIG=""

RGXNUMERIC='^[0-9]+$'




RESULTFILE="$CURDIR/result.txt"
ERRORFILE="$CURDIR/error.txt"

clear
echo
echo "Make sure you run program in user home directory"
echo "Current Directory=$PWD"
read -p "" CONTINUE
if [[ ! $CONTINUE =~ [y]|[yY][eE][sS]  ]]
then
    exit 
fi

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

function getBackupInformation
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

function getRestoreInformation
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

function getRemoveInformation
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

# CHCEK VALID VARIABLES
function checkBackupVariables
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

function checkRestorevariables
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

function checkRemoveVariables
{
        if [ -z $FILEDIR ] || [ -z $DBNAME ]
        then
                echo "Input Missing"
                exit 1
        fi
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

function BackupRemoveUnecessaryBackFiles
{
	while true;
	do
		display "Unnecessary Files"
		read -p "Remove unecessary files? [Y/N]" YN
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

function RestoreRemoveFiles
{
        showresult "Moved $FILELOC/$TEMPDIR to $FILELOC/$FILEDIR" 
        rm $BKFILE $DBFILE $FINAL 2>>$ERRORFILE
        showresult "Removed unnessary files $BKFILE $DBFILE $FINAL"
}


function RemoveFiles
{
        if [ -d "$FILELOC/$FILEDIR" ]
        then
                while true;
                do
                        display "Remove File Folder"
                        echo "This will remove directory $FILELOC/$FILEDIR and files within it permanently"
                        read -p " Continue [Y/N]: " YN
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
                read -p "This will remove database $DBNAME permanently [Y/N]: " YN
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
                read -p "Do you want to remove database user $DBUSER [Y/N]: " YN
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
                read -p "Is this a test site? [Y/N]: " YN
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
                        read -p "Do you want to update the site URL? [Y/N]: " YN
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

function CustomMOTD
{
    apt update
    apt install screenfetch
    echo "#! $(which bash)" > /etc/update-motd.d/motd
    echo "echo 'GENERAL INFORMATION'" >> /etc/update-motd.d/motd
    echo "$(which screenfetch)" >> /etc/update-motd.d/motd
    chmod -x /etc/update-motd.d/*
    chmod +x /etc/update-motd.d/motd
    showresult "Created New Message of the day (MOTD)"
}

function CustomPrompt
{
    echo "PS1='\[\e[0m\][\[\e[0;95m\]\d\[\e[0m\]:\[\e[0;95m\]\t\[\e[0m\]]\[\e[0m\]@\[\e[0;96m\]\h\[\e[m\] \[\e[0m\]<\[\e[0;92m\]\w\[\e[0m\]>\[\e[m\]\n\[\e[0m\][\[\e[0;38;5;208m\]\j\[\e[0m\]]\[\e[0;93m\]\u\[\e[m\] \[\e[0;97m\]\$\[\e[m\] \[\e0'" >> $CURDIR/.bashrc
    showresult "Created Custom Prompt"
}


function installswap
{
    while true;
    do
        read -p "Do you want to install swap? [Y/N]: " YN
        case $YN in 
            [yY]|[yY][eE][sS])
                while true;
                do
                    display "Install Swap"
                    read -p "Install Swap Size in GB: " SWAPSIZE
                    case $SWAPSIZE in [1]|[2]|[3]|[4]|[5]|[6]|[7]|[8]|[9])
                            echo "Configuring Swap ..."
                            fallocate -l ${SWAPSIZE}G /swapfile 2>>$ERRORFILE
                            dd if=/dev/zero of=/swapfile bs=1024 count=$((1048576 * SWAPSIZE)) 2>>$ERRORFILE
                            chmod 600 /swapfile 2>>$ERRORFILE
                            mkswap /swapfile 2>>$ERRORFILE
                            swapon /swapfile 2>>$ERRORFILE
                            echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
                            mount -a 2>>$ERRORFILE
                            showresult "Swap is setted to $SWAPSIZE GB" 
                            pauseandclear
                            break
                            ;;
                        [0])
                            break
                            ;;
                        *) 
                            echo "Please, identify 1-9"
                        ;;
                    esac
                done
                break
                ;;
            [nN]|[nN][oO])
                showresult "Skip Installing Swap"
                break
                ;;
            *)
                echo "Please Answer with Yes or No."
                ;;
        esac
    done

}

function UpdateUpgrade
{
    display "Update and Upgrade Server"
    while true;
    do
        read -p "Unpdate and Upgrade Server Now? [Y/N]: " UP
        case $UP in 
            [yY]|[yY][eE][sS])
                apt update 2>>$ERRORFILE
                apt upgrade -y 2>>$ERRORFILE
                showresult "Update, Upgrade Done" 
                pauseandclear
                break
                ;;
            [nN]|[nN][oO])
                break
                ;;
            *) 
                echo "Please, answer Yes or No"
            ;;
        esac
    done
}

function ConfigHostName
{
    display "Set Host name"
    while true;
    do
        read -p "Congfigure HostName? [Y/N]: " HN
        case $HN in 
            [yY]|[yY][eE][sS])
                read -p "What is your Host Name (HostName): " HOSTNAME
                if [ -z $HOSTNAME ] 
                then 
                    HOSTNAME=HostName 
                fi
                hostnamectl set-hostname $HOSTNAME 2>>$ERRORFILE
                showresult "Host Name Setted to $HOSTNAME"
                pauseandclear
                break
                ;;
            [nN]|[nN][oO])
                break
                ;;
            *) 
                echo "Please, answer Yes or No"
            ;;
        esac
    done
}

function ConfigTimeZone
{
    display "Configure Time Zone"
    while true;
    do
        read -p "Congfigure Timezone? [Y/N]: " TZ
        case $TZ in 
            [yY]|[yY][eE][sS])
                read -p "What Time Zone (Asia/Bangkok): " TIMEZONE
                if [ -z $TIMEZONE ] 
                then 
                    TIMEZONE=Asia/Bangkok 
                fi
                timedatectl set-timezone $TIMEZONE 2>>$ERRORFILE
                showresult "Timezone Setted to $TIMEZONE"
                pauseandclear
                break
                ;;
            [nN]|[nN][oO])
                break
                ;;
            *) 
                echo "Please, answer Yes or No"
            ;;
        esac
    done
}

function InstallZipUnzip
{
    display "Install Zip/Unzip"
    while true;
    do
        read -p "Install Zip and Unzip Now? [Y/N]: " ZIP
        case $ZIP in 
            [yY]|[yY][eE][sS])
                apt install -y zip unzip 2>>$ERRORFILE
                showresult "Zip/Unzip Installed"
                pauseandclear
                break
                ;;
            [nN]|[nN][oO])
                break
                ;;
            *) 
                echo "Please, answer Yes or No"
            ;;
        esac
    done
}

function InstallFirewall
{
    display "Install Firewall"
    while true;
    do
        read -p "Do you want to install firewall Now? [Y/N]: " FIREWALL
        case $FIREWALL in 
            [yY]|[yY][eE][sS])
                if [ -e /etc/init.d/ufw ]
                then
                    showresult "UFW firewall already installed"
                else
                    apt install ufw
                fi
                while true;
                do
                    echo "This might interupt server connection please be sure."
                    echo "Options: [Type 'SHOW' 'ALLOW' 'DENY' 'ENABLE' 'DISABLE' 'DEFAULT' 'EXIT']"
                    read -p "Do you want to Allow oer Deny Enable Disable Firewall now?: " ADED
                    case $ADED in
                        [sS][hH][oO][wW])
                            ufw status
                            ;;
                        [aA][lL][lL][oO][wW])
                            echo "This might interupt server connection please be sure."
                            read -p "Please specify port number to allow: " ALLOWPORT
                            if [[ $ALLOWPORT =~ $RGXNUMERIC ]] ; then
	                            ufw allow $ALLOWPORT 2>> $ERRORFILE
                                showresult "UFW allowed port: $ALLOWPORT"
                            else    
                                echo "please specify port number"
                            fi
                            ;;
                        [dD][eE][nN][yY])
                            echo "This might interupt server connection please be sure."
                            read -p "Please specify port number to deny: " DENYPORT
                            if [[ $DENYPORT =~ $RGXNUMERIC ]] ; then
	                            ufw allow $ALLOWPORT 2>> $ERRORFILE
                                showresult "UFW denied port: $DENYPORT"
                            else    
                                echo "please specify port number"
                            fi
                            ;;
                        [eE][nN][aA][bB][lL][eE])
                                RGXYES="^[yY]|[yY][eE][sS]$"
                                read -p "This might interupt server connection, do you want to continue? [Y/N]: " CONTINUE
                                if [[ $CONTINUE =~ $RGXYES ]]
                                then
                                    ufw enable 2>> $ERRORFILE
                                    showresult "UFW Activated"
                                fi
                            ;;
                        [dD][iI][sS][aA][bB][lL][eE])
                            ufw disable 2>> $ERRORFILE
                            showresult "UFW Deactivated"
                            ;;
                        [dD][eE][fF][aA][uU][lL][tT])
                            RGXALLOW="^[aA][lL][lL][oO][wW]$"
                            RGXDENY="^[dD][eE][nN][yY]$"
                            echo "This might interupt server connection please be sure."
                            read -p "Please specify default ports actions ALLOW or DENY? [Y/N]: " DEFAULT
                            if [[ $DEFAULT =~ $RGXALLOW ]] ; 
                            then
	                            ufw default allow 2>> $ERRORFILE
                                showresult "UFW default action: Allow"
                            elif [[ $DEFAULT =~ $RGXDENY ]]
                            then
                                ufw default deny 2>> $ERRORFILE
                                showresult "UFW default action: Deny"
                            else    
                                echo "Please Specify 'ALLOW' or 'DENY'"
                            fi
                            ;;
                        [eE][xX][iI][tT])
                            break
                            ;;
                        *)
                            echo "Options: Type 'ALLOW' 'DENY' 'ENABLE' 'DISABLE' 'EXIT'"
                            ;;
                    esac

                done
                pauseandclear
                break
                ;;
            [nN]|[nN][oO])
                break
                ;;
            *) 
                echo "Please, answer Yes or No"
            ;;
        esac
    done
}

function InstallWebmin
{
    display "Install Webmin"
    while true;
    do
        read -p "Install Webmin Now? [Y/N]: " WEBMIN
        case $WEBMIN in 
            [yY]|[yY][eE][sS])
                echo "deb https://download.webmin.com/download/repository sarge contrib" >> /etc/apt/sources.list
                cd
                wget https://download.webmin.com/jcameron-key.asc 2>>$ERRORFILE
                apt-key add jcameron-key.asc 2>> $ERRORFILE
                apt-get install apt-transport-https 2>>$ERRORFILE
                apt-get update  2>> $ERRORFILE
                apt-get install webmin 2>>$ERRORFILE
                showresult "Webmin Installed"
                pauseandclear
                break
                ;;
            [nN]|[nN][oO])
                break
                ;;
            *) 
                echo "Please, answer Yes or No"
            ;;
        esac
    done
}

function InstallNetDATA
{
    display "Install NetDATA"
    while true;
    do
        read -p "Install NetData Now? [Y/N]: " NETDATA
        case $NETDATA in 
            [yY]|[yY][eE][sS])
                bash <(curl -Ss https://my-netdata.io/kickstart.sh)
                showresult "NetDATA Installed"
                pauseandclear
                break
                ;;
            [nN]|[nN][oO])
                break
                ;;
            *) 
                echo "Please, answer Yes or No"
            ;;
        esac
    done
}

function securemysql
{
    mysql_secure_installation <<EOF

n
y
y
y
y
y
EOF
}


function InstallMariadb
{
    display "Install MariaDB"
    while true;
    do
        read -p "Install Mariadb Server Now? [Y/N]: " MDB
        case $MDB in 
            [yY]|[yY][eE][sS])
                apt install -y mariadb-server  2>>$ERRORFILE
                securemysql
                showresult "MariaDB installed"
                pauseandclear
                break
                ;;
            [nN]|[nN][oO])
                break
                ;;
            *) 
                echo "Please, answer Yes or No"
            ;;
        esac
    done
}



function InstallApacheWPCLI
{
    display "Installing Wordpress Console Line Interfacie (WP-CLI)"
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar 2>>$ERRORFILE
    chmod +x wp-cli.phar 2>>$ERRORFILE
    mv wp-cli.phar /usr/local/bin/wp 2>>$ERRORFILE
    showresult "WP-CLI for Apache Installed"
}

function InstallWordpressApache
{
    display $'Wordpress for Apache Server \n*   This will install Following \n*     - wordpress \n*     - wp-cli'
    while true;
    do
        read -p "Install Wordpress Now? [Y/N]: " WPAPCHE
        case $WPAPCHE in 
            [yY]|[yY][eE][sS])
                SITELOC=/var/www/html
                mkdir $SITELOC 2>>$ERRORFILE
                cd $SITELOC 2>>$ERRORFILE
                wget https://wordpress.org/latest.zip 2>>$ERRORFILE
                unzip latest.zip 2>>$ERRORFILE
                chown -R www-data:www-data wordpress 2>>$ERRORFILE
                rm latest.zip 2>>$ERRORFILE
                showresult "Wordpress Installed at $SITELOC"
                InstallApacheWPCLI
                pauseandclear
                break
                ;;
            [nN]|[nN][oO])
                break
                ;;
            *) 
                echo "Please, answer Yes or No"
            ;;
        esac
    done
}

function InstallApache
{
    display "Install Apache Virtual Server"
    while true;
    do
        read -p "Install Apache Web Server Now? [Y/N]: " APCHE
        case $APCHE in 
            [yY]|[yY][eE][sS])
                InstallMariadb 2>>$ERRORFILE
                apt-get install -y php php-mysql php-zip php-curl php-gd php-mbstring php-xml php-xmlrpc 2>>$ERRORFILE
                showresult "Apache installed"
                pauseandclear
                InstallWordpressApache
                break
                ;;
            [nN]|[nN][oO])
                break
                ;;
            *) 
                echo "Please, answer Yes or No"
            ;;
        esac
    done
}

function InstallOLSWPCLI
{
    display "Installing Wordpress Console Line Interfacie (WP-CLI)"
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar 2>>$ERRORFILE
    chmod +x wp-cli.phar 2>>$ERRORFILE
    mv wp-cli.phar /usr/local/bin/wp 2>>$ERRORFILE
    cp /usr/local/lsws/lsphp74/bin/php /usr/bin/ 2>>$ERRORFILE
    showresult "WP CLI for OpenLiteSpeed installed"
}

function InstallWordpressOLS
{
    display $'Wordpress for Apache Server \n*   This will install Following \n*     - wordpress \n*     - wp-cli'
    while true;
    do
        read -p "Install Wordpress Now? [Y/N]: " WPOLS
        case $WPOLS in 
            [yY]|[yY][eE][sS])
                SITELOC=/usr/local/lsws/sites
                mkdir $SITELOC 2>>$ERRORFILE
                cd $SITELOC 2>>$ERRORFILE
                wget https://wordpress.org/latest.zip 2>>$ERRORFILE
                unzip latest.zip 2>>$ERRORFILE
                chown -R nobody:nogroup wordpress 2>>$ERRORFILE
                rm latest.zip 2>>$ERRORFILE
                showresult "Wordpress Installed at $SITELOC"
                InstallOLSWPCLI
                pauseandclear
                break
                ;;
            [nN]|[nN][oO])
                break
                ;;
            *) 
                echo "Please, answer Yes or No"
            ;;
        esac
    done
}



function InstallOpenLiteSpeed
{
    display "Installing OpenLiteSpeed Virtual Server"
    while true;
    do
        read -p "Install OpenLiteSpeed Web Server Now? [Y/N]: " OLS
        case $OLS in 
            [yY]|[yY][eE][sS])
                InstallMariadb
                wget --no-check-certificate https://raw.githubusercontent.com/litespeedtech/ols1clk/master/ols1clk.sh && bash ols1clk.sh 2>>$ERRORFILE
                apt-get install -y lsphp73 lsphp73-curl lsphp73-imap lsphp73-mysql lsphp73-intl lsphp73-pgsql lsphp73-sqlite3 lsphp73-tidy lsphp73-snmp lsphp73-json lsphp73-common lsphp73-ioncube 2>>$ERRORFILE
                rm ols1clk.sh 2>>$ERRORFILE
                showresult "OpenLiteSpeed installed"
                cat /usr/local/lsws/password >> $RESULTFILE
                pauseandclear
                InstallWordpressOLS
                break
                ;;
            [nN]|[nN][oO])
                break
                ;;
            *) 
                echo "Please, answer Yes or No"
            ;;
        esac
    done
}

function InstallCron
{
    display "Install Server Cron Schedule"
    while true;
    do
        read -p "Install reset cron schedule Now? [Y/N]: " CRON
        case $CRON in 
            [yY]|[yY][eE][sS])
                crontab -l > mycron 2>>$ERRORFILE
                #echo new cron into cron file
                echo "30 3 * * * shutdown -r now" >> mycron
                #install new cron file
                crontab mycron 2>>$ERRORFILE
                rm mycron 2>>$ERRORFILE
                showresult "Cron Installed"
                break
                ;;
            [nN]|[nN][oO])
                break
                ;;
            *) 
                echo "Please, answer Yes or No"
            ;;
        esac
    done
}

function SelectVirtualHostServer
{
    display "Select Vertual Host Server Type"
    while true;
    do
        read -p "Select your virtual host server 'Apache' Or 'OpenLiteSpeed'? (A/O/C)" AOC
        case $AOC in 
            [aA]|[aA][pP][aA][cC][hH][eE])
                InstallApache
                break
                ;;
            [oO]|[oO][pP][eE][nN][lL][iI][tT][eE][sS][pP][eE][eE][dD])
                InstallOpenLiteSpeed
                break
                ;;
            [cC]|[cC][aA][nN][cC][eE][lL])
                echo "Canceled"
                break
                ;;
            *) 
                echo "Please, answer Apache or OpenLiteSpeed or Cancel"
            ;;
        esac
    done
}


function InstallWebServer
{
    display "Install Web Server"
    while true;
    do
        read -p "Do you want to install Web Server Now? [Y/N]: " WS
        case $WS in 
            [yY]|[yY][eE][sS])
                SelectVirtualHostServer
                InstallCron
                break
                ;;
            [nN]|[nN][oO])
                break
                ;;
            *) 
                echo "Please, answer Yes or No"
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

function Backup
{
    clear
    getBackupInformation
    checkBackupVariables
    backupbackup
    pauseandclear
    ArchiveDirectory
    pauseandclear
    exportDatabase
    pauseandclear
    ArchiveBackupFiles
    pauseandclear
    BackupRemoveUnecessaryBackFiles
    pauseandclear
    Finalize
}

function Restore
{
    clear
    getRestoreInformation
    checkRestorevariables
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
    RestoreRemoveFiles
    pauseandclear
    UpdateURL
    pauseandclear
    completeURLChanged
    Finalize
    echo "***************** WP INFO *****************"
    wp --info
}


function Remove
{
    clear
    getRemoveInformation
    checkRemoveVariables
    RemoveFiles
    pauseandclear
    RemoveDatabase
    pauseandclear
    RemoveDatabaseUser
    Finalize
}


function Newsvr
{
    CustomPrompt
    CustomMOTD
    UpdateUpgrade
    installswap
    ConfigTimeZone
    ConfigHostName
    InstallZipUnzip
    InstallFirewall
    InstallWebmin
    InstallNetDATA
    InstallWebServer
    pauseandclear
    Finalize
    echo "***************** WP INFO *****************"
    wp --info
}

function InstallWordpress
{
    if [ -e "/var/www" ]
    then
        InstallWordpressApache
    fi
    if [ -e "/usr/local/lsws" ]
    then
        SITELOC=/usr/local/lsws/sites
        if [ ! -e $SITELOC ]
        then
            mkdir $SITELOC
        fi
        InstallWordpressOLS
    fi
}

function InstallWPCLI
{
    if [ -e "/var/www" ]
    then
        InstallApacheWPCLI
    fi
    if [ -e "/usr/local/lsws" ]
    then
        SITELOC=/usr/local/lsws/sites
        if [ ! -e $SITELOC ]
        then
            mkdir $SITELOC
        fi
        
        InstallOLSWPCLI
    fi
}

function main
{
    while true;
    do
        echo
        echo "Select Actions"
        echo "=============="
        echo
        echo "   New)       NEW Server Setup"
        echo "   MOTD)      Install new MOTD"
        echo "   PROMPT)    My Custom Prompt"
        echo "   Backup)    BACKUP Website"
        echo "   Restore)   RESTORE Website"
        echo "   Remove)    REMOVE Website"
        echo "   DBServer)  Install DBSERVER - Mariadb"
        echo "   Webserver) Install Webserver"
        echo "   Webmin)    Install WEBMIN (Large)"
        echo "   NetData)   Install NetData (Large)"
        echo "   Wordpress) Install WORDPRESS"
        echo "   WPCLI)     Install WPCLI"
        echo "   UFW)       Install UFW firewall"
        echo "   Test)      TEST Environment Configuration"
        echo "   X)         EXIT Program"
        echo "=================================================="
        echo
        read -p "What is your action?: " ANS
        case $ANS in 
            [nN][eE][wW])
                Newsvr
                ;;
            [mM][oO][tT][dD])
                CustomMOTD
                ;;
            [pP][rR][oO][mM][pP][tT])
                CustomPrompt
                ;;
            [bB][aA][cC][kK][uU][pP])
                Backup
                ;;
            [rR][eE][sS][tT][oO][rR][eE])
                Restore
                ;;
            [rR][eE][mM][oO][vV][eE])
                Remove
                ;;
            [dD][bB][sS][eE][rR][vV][eE][rR])
                InstallMariadb
                ;;
            [wW][eE][bB][sS][eE][rR][vV][eE][rR])
                InstallWebServer
                ;;
            [wW][eE][bB][mM][iI][nN])
                InstallWebmin
                ;;
            [nN][eE][tT][dD][aA][tT][aA])
                InstallNetDATA
                ;;
            [wW][oO][rR][dD][pP][rR][eE][sS][sS])
                InstallWordpress
                cat $RESULTFILE
                wp --info
                pauseandclear
                ;;
            [wW][pP][cC][lL][iI])
                InstallWPCLI
                cat $RESULTFILE
                wp --info
                pauseandclear
                ;;
            [uU][fF][wW])
                InstallFirewall
                cat $RESULTFILE
                pauseandclear
                ;;
            [tT][eE][sS][tT])
                ConfigureTestSite
                cat $RESULTFILE
                wp --info
                pauseandclear
                ;;
            [xX]|[eE][xX][iI][tT])
                display "Exit Program"
                break
                ;;
            *)
                display "Please use specific letter or the word written in uppercase"
                pauseandclear
                ;; 
        esac          
    done
}

main