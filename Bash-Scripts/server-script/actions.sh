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

FILELOC=""
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
read -p "Do you want to continue? [y/n]: " CONTINUE
if [[ ! $CONTINUE =~ [y]|[yY][eE][sS]  ]]
then
    exit 
fi

echo " ----==== RESULT INFORMATION ====----" > $RESULTFILE

function initialize
{


    if [ -d /usr/local/lsws ]
    then
        FILELOC=/usr/local/lsws/sites
    fi
    if [ -d /var/www ]
    then
        FILELOC=/var/www
    fi
}




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

function processed
{
    echo $1
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

function run
{
    LASTCODE=$?
    if [ $LASTCODE -eq 0 ]
    then
        # Successfully Executed
        showresult $2
        return 0
    else
        # Execution Failed
        showresult $3
        if ( $($4) )
        then
            # if true exit script
            exit 1
        fi
        return 1
    fi

}





function RetrieveDatabaseName
{
    echo "Retrieving Database Name from $WPCONFIG"
    run "$(DBNAME=$(cat $WPCONFIG | grep DB_NAME | cut -d \' -f 4) 2>>$ERRORFILE)" "Retrieved Database Name '$DBNAME' from $WPCONFIG" "Could not Retrieve Database Name from $WPCONFIG" true
}

function RetrieveDatabaseUser
{
    echo "Retrieving Database Username from $WPCONFIG"
    run "$(DBUSER=$(cat $WPCONFIG | grep DB_USER | cut -d \' -f 4) 2>>$ERRORFILE)" "Retrieved Database User '$DBUSER' from $WPCONFIG" "Could not retrieve Database User from $WPCONFIG" true
}

function CheckFolder
{
    if [ -e $1 ]
    then
        return 0
    else
        showresult "Folder $1 not found"
        if [ "$2" == "critical" ]
        then
            exit 1
        fi
        return -1
    fi
    
}

function CheckFile
{
    if [ -e $1 ]
    then
        return 0
    else
        showresult "File $1 not found"
        if [ "$2" == "critical" ]
        then
            exit 1
        fi
        return -1
    fi
}

function getBackupInformation
{
	display "Collect Information for backup"
	read -p "Please input files directory:" FILEDIR
	WPCONFIG=$FILELOC/$FILEDIR/wp-config.php
	RetrieveDatabaseName
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
        read -p "Please, input target database name (Blank for same as original): " DBNAME
        read -p "Please, input target database username (Blank for same as original): " DBUSER
        read -p "Please, input target database password for '$DBUSER' (Blank for same as original): " DBPASS
        read -p "Please, input new website URL with http/https: " URL
        FINAL=latest.$ORIGINALDIR.zip
        BKFILE=$ORIGINALDIR.zip
}

function getRemoveInformation
{
    display "Collect Information For Website Removal"
    read -p "Please input the website File Directory: " FILEDIR
	WPCONFIG=$FILELOC/$FILEDIR/wp-config.php
        if ($(CheckFile $WPCONFIG "critical") )
        then
                RetrieveDatabaseName
                RetrieveDatabaseUser
        fi
}

# CHCEK VALID VARIABLES
function checkBackupVariables
{
    if ($(CheckFolder $FILELOC "critical"))
    then
		processed "Directory $FILELOC CHECKED"
    fi

	if [ -z "$FILEDIR" ];
	then
		showresult "Files Directory INPUT IS EMPTY" 
		exit 1
	else
        if ($(CheckFolder $FILELOC/$FILEDIR "critical"))
		then
			processed "$FILELOC/$FILEDIR CHECKED"
		fi
	fi

	processed "Input Information CHECKED.  Start Backing up $FILELOC/$FILEDIR Files"
}

function checkRestorevariables
{
    if [ -z $DBUSER ]
    then
        RetrieveDatabaseUser
    fi

    if [ -z $DBNAME ]
    then
        RetrieveDatabaseName
    fi

    if [ -z $FILEDIR ]
    then
            FILEDIR=$ORIGINALDIR
            processed "Recover to the same directory '$ORIGINALDIR'"
    fi

    WPCONFIG=$FILELOC/$FILEDIR/wp-config.php
    CheckFile $WPCONFIG "critical"

    if [ -z $URL ]
    then
            processed "URL input error: $URL"
            exit 1
    fi

    if ( $(CheckFile $CURDIR/$FINAL "critical"))
    then
            processed "Original Backup $CURDIR/$FINAL Found"
    fi

    if ( $(CheckFolder $FILELOC "critical"))
    then
            processed "$FILELOC Found"
    fi
    processed "Variables Checked"
}


function backupbackup
{
	# BACKUP FINAL FILE
    if ( $(CheckFile $FINAL "optional") ) 
    then
		display "Found Previous Backup File '$FINAL'"
		run "$(mv $FINAL $BKFINAL)" "Backed up previous backup file $FINAL to $BKFINAL" "Backup Prevouse Backup $FINAL to $BKFINAL Failed" true
	fi
	# BACKUP FINAL FILE
    if ( $(CheckFile $FINAL.md5 "optional") )
	then
		display "Found Previous Backup Hash File '$FINAL.md5'"
		run "$(mv $FINAL.md5 $BKFINAL.md5)" "Backed up previous backup file $FINAL.md5 to $BKFINAL.md5" "Backup Prevouse Backup $FINAL.md5 to $BKFINAL.md5 Failed" true
	fi

}

# ARCHIVING DIRECTORY
function ArchiveDirectory
{
	cd $FILELOC
    echo "Archiving $FILELOC/$FILEDIR ..."
	run "$(zip -r $BKFILE $FILEDIR 2>>$ERRORFILE)" "$FILELOC/$FILEDIR Archived" "Archiving $FILELOC/$FILEDIR failed" true
	run "$(mv $BKFILE $CURDIR 2>>$ERRORFILE)" "$FILELOC/$FILEDIR Moved to $CURDIR" "Moving $FILELOC/$FILEDIR failed" true
	cd $CURDIR
	processed 
}

function CheckMD5
{
    if ( $(CheckFile $CURDIR/$FINAL.md5 "Optional" ))
    then
        echo "MD5 file found, attempt to check agaist it"
        if [ $(md5sum -c ${FINAL}.md5) -eq 0 ]
        then
            return true
        else
            showresult "Backup File corrupted or not the same as encrypted MD5"
            exit 1
        fi
    fi
}

# MOVE ARCHIVED FILE TO DIRECTORY
function PrepareEnvironment
{
    if ( $(CheckFile $CURDIR/$FINAL "critical") )
    then
        CheckMD5
        echo "copying $FINAL to $FILELOC"...
        run "$(cp $FINAL $FILELOC)" "$FINAL Copied to $FILELOC" "Copying $FINAL to $FILELOC failed" true 
        cd $FILELOC
        display "Unpacking $FINAL ..."
        run "$(unzip -o $FINAL 2>> $ERRORFILE)" "Unziped $FINAL Successful" "Unzip $FINAL failed" true
        cd $CURDIR
        processed "$FINAL unpacked."
    fi
}

function RemoveExistedDirectory
{
    if ($(CheckFolder $FILELOC/$FILEDIR "critical" ))
    then
        echo "removing existing directory"
        run "$(rm -r $FILELOC/$FILEDIR)" "$FILELOC/$FILEDIR found and removed" "removing $FILELOC/$FILEDIR failed" true
    fi
}

function RestoringFileDirectory
{
    echo "Recover Directory from Backup"
    run "$(unzip -o $BKFILE -d $FILELOC/$TEMPDIR 2>>$ERRORFILE)" "Recovered $BKFILE to $FILELOC/$TEMPDIR"  "Recovered $BKFILE to $FILELOC/$TEMPDIR Failed" true
    run "$(mv $FILELOC/$TEMPDIR/$ORIGINALDIR $FILELOC/$FILEDIR 2>>$ERRORFILE)" "Placed file to $FILELOC/$FILEDIR" "Can not placed file to $FILELOC/$FILEDIR" true
    run "$(rm -r $FILELOC/$TEMPDIR 2>>$ERRORFILE)" "$FILELOC/$TEMPDIR removed" "Removing $FILELOC/$TEMPDIR failed" false
    run "$(chown -R nobody:nogroup $FILEDIR 2>>$ERRORFILE)" "Setted Permission to $FILEDIR" "Setting Permission to $FILEDIR failed" false
}


function configurewpconfig
{

    run "$(ORIGINALDB=$(cat $WPCONFIG | grep DB_NAME | cut -d \' -f 4) 2>> $ERRORFILE)" "Original Database Name '$ORIGINALDB' retrieved" "Original Database Name retrieving failed" true
    run "$(ORIGINALUSR=$(cat $WPCONFIG | grep DB_USER | cut -d \' -f 4) 2>>$ERRORFILE)" "Original Database User '$ORIGINALUSR' retrieved" "Retrieving Original Database Username failed" true
    run "$(ORIGINALPASS=$(cat wp-config.php | grep DB_PASSWORD | cut -d \' -f 4) 2>>$ERRORFILE)" "Retrieved Database Password" "Retrieving Database Password failed" true

    DBFILE=$ORIGINALDB.sql
    CheckFile $DBFILE "critical"
    
    if [ ! "$ORIGINALDB" == "$DBNAME" ]
    then
            run "$(sed -i "/DB_NAME/s/'[^']*'/'$DBNAME'/2" $WPCONFIG 2>>$ERRORFILE)" "Edited database name to ($DBNAME) in $WPCONFIG" "Editing Database name failed" true
    fi

    if [ ! "$ORIGINALUSR" == "$DBUSER" ]
    then
            run "$(sed -i "/DB_USER/s/'[^']*'/'$DBUSER'/2" $WPCONFIG 2>>$ERRORFILE)"  "Edited database username to ($DBUSER) in $WPCONFIG" "Editing database username in $WPCONFIG failed" true
    fi
    if [ ! "$ORIGINALPASS" == "$DBPASS" ]
    then
            run "$(sed -i "/DB_PASSWORD/s/'[^']*'/'$DBPASS'/2" $WPCONFIG 2>>$ERRORFILE)" "Edited database password to ($DBPASS) in $WPCONFIG" "Editing database password in $WPCONFIG failed" true
    fi

}

# EXPORT DATABASE
function exportDatabase
{
	echo "Dumping Database $DBNAME to $DBFILE"
	# mysqldump -u $DBUSER --password="$DBPASS" $DBNAME > $DBFILE 2>>$ERRORFILE
	run "$(mysqldump -u root $DBNAME > $DBFILE 2>>$ERRORFILE)" "Database exported to $DBFILE" "Exporting database failed" true
}

# ARCHIVE BACKUP FILES
function ArchiveBackupFiles
{
	echo "Archiving files..."
	run "$(zip $FINAL $BKFILE $DBFILE 2>>$ERRORFILE)" "Archived $BKFILE and $DBFILE to $FINAL" "Archiving $BKFILE and $DBFILE to $FINAL failed" true
    run "$(md5sum $FINAL > $FINAL.md5 2>>$ERRORFILE)" "Created MD5 checksum for $FINAL > $FINAL.md5" "Creating MD5 Checksum for $FINAL failed" false
}


function CreateDBUser
{
        display "Create Database User"
        run "$(mysql -u root -e "CREATE USER $DBUSER IDENTIFIED BY '$DBPASS';" 2>>$ERRORFILE)" "Created Database User $DBUSER" "Creating database user $DBUSER failed" true
}

function DropDatabase
{
        display "droping $DBNAME database"
        run "$(mysql -u root -e "DROP DATABASE $DBNAME;" 2>> $ERRORFILE)" "Dropped database $DBNAME" "Droping database $DBNAME failed" true 
}

function createDatabase
{
        display "create database $DBNAME"
        run "$(mysql -u root -e "CREATE DATABASE $DBNAME;" 2>>$ERRORFILE)" "Created database $DBNAME" "Creating database $DBNAME failed" true
        run "$(mysql -u root -e "GRANT ALL PRIVILEGES ON $DBNAME.* TO $DBUSER;" 2>>$ERRORFILE)" "Granted Privileges to $DBUSER" "Granting privileges to $DBUSER failed" true
}

function ImportDatabase
{
        display "importing database from $DBFILE"
        run "$(mysql -u $DBUSER --password="$DBPASS" $DBNAME < $DBFILE 2>>$ERRORFILE)" "Imported $DBFILE to database $DBNAME" "Importing $DBFILE to database $DBNAME failed" true
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
			run "$(rm $DBFILE)" "Removed $DBFILE" "Removing $DBFILE failed" false
			run "$(rm $BKFILE)" "Removed $BKFILE" "Removing $BKFILE failed" false
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
    run "$(rm $BKFILE $DBFILE $FINAL 2>>$ERRORFILE)" "Removed $BKFILE $DBFLE $FINAL" "Removing $BKFILE $DBFILE $FINAL failed" false 
}


function RemoveFiles
{
    if ($(CheckFile $FILELOC/$FILEDIR "critical" ))
    then
            while true;
            do
                    display "Remove File Folder"
                    echo "This will remove directory $FILELOC/$FILEDIR and files within it permanently"
                    read -p " Continue [Y/N]: " YN
                    case $YN in
                            [yY]|[yY][eE][sS])
                                    RemoveExistedDirectory
                                    break
                                    ;;
                            [nN]|[nN][oO])
                                    echo "skipped removing $FILELOC/$FILEDIR"
                                    break
                                    ;;
                            *)
                                    echo "Please answer Y/N"
                                    ;;
                    esac
            done

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
                            run "$(mysql -u root -e "DROP DATABASE $DBNAME;" 2>> $ERRORFILE)" "Removed $DBNAME" "Removing $DBNAME failed" true
                            break
                            ;;
                    [nN]|[nN][oO])
                            showresult "skipp removing database $DBNAME"
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
                            run "$(mysql -u root -e "DROP USER $DBUSER;" 2>> $ERRORFILE)" "Removed Database User $DBUSER" "Removing database user $DBUSER failed" true
                            break
                            ;;
                    [nN]|[nN][oO])
                            echo "skipping remove database user $DBUSER"
                            break
                            ;;
                    *)
                            echo "Please answer Y/N"
                            ;;
            esac
    done
}

function showURL
{
    display "homeurl and siteurl in table ${TABLEPREF}options is shown below"
    mysql -u $DBUSER --password="$DBPASS" $DBNAME -e "$SELECTCOMMAND"
    mysql -u $DBUSER --password="$DBPASS" $DBNAME -e "$SELECTCOMMAND" >> $RESULTFILE
}

function UpdateURL
{
    display "Modifying HomeURL and SiteURL"
    run "$(TABLEPREF=$(cat $WPCONFIG | grep "\$table_prefix" | cut -d \' -f 2) 2>>$ERRORFILE)" "Retrieved Table prefix '$TABLEPREF'" "Retrieving Table Prefix failed" true
    DBCOMMAND="UPDATE ${TABLEPREF}options SET option_value = '$URL' WHERE option_id =1 OR option_id=2;"
    SELECTCOMMAND="SELECT * FROM ${TABLEPREF}options WHERE option_id=1 OR option_id=2;"
    run "$(mysql -u $DBUSER --password="$DBPASS" $DBNAME -e "$DBCOMMAND" 2>>$ERRORFILE)" "Updated homeurl/siteURL to $URL" "Updating homeurl/siteURL failed" true
    showURL
}

function discourageSearchEnging
{
    run "$(wp option set blog_public 0 --allow-root 2>> $ERRORFILE)" "Discouraged search engines from indexing the site" "Discoruaging search engines failed" false
}

function disablePlugins
{
    while true;
    do
        echo
        echo " List Plugins and status "
        wp plugin list --allow-root
        echo
        read -p "(Type 'DONE' to exit) Type plugin name to disable: " PLUGIN
        if [ "$PLUGIN" == "DONE" ]
        then
            break
        else
            run "$(wp plugin deactivate $PLUGIN --allow-root 2>> $ERRORFILE)" "Disabled plugin $PLUGIN" "Disabling plugin $Plugin failed" false
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
            run "$(wp plugin update --all --allow-root 2>> $ERRORFILE)" "Updated all plugins" "Updating all plugins failed" false
        else
            run "$(wp plugin update $PLUGIN --allow-root 2>> $ERRORFILE)" "Updated plugin $PLUGIN" "Updating plugin $PLUGIN failed" false 
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
                completeURLChanged
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

    while true;
    do
        read -p "Do you want to update the site URL? [Y/N]: " YN
        case $YN in
            [yY]|[yY][eE][sS])
                
                echo "*** THIS IS IMPORTANT DO NOT MISS TYPED ***"
                echo "*** Please check and recheck before press ENTER" 
                read -p "Please input your original website url with http/https: " ORIGINALURL
                if [ -z $URL ]
                then
                    read -p "Please input your new website url with http/https: " URL
                fi
                if [ -z $FILEDIR ]
                then
                    read -p "Please input working wordpress directory: " FILEDIR
                fi
                cd $FILELOC/$FILEDIR
                echo "working .."
                wp search-replace $ORIGINALURL $URL --all-tables --allow-root 2>>$ERRORFILE
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
}

function CustomMOTD
{
    run "$(apt update -y 2>>$ERRORFILE)" "Updated Server" "Update server failed" false
    run "$(apt install screenfetch -y 2>> $ERRORFILE)" "Installed screenfetch" "Install screenfetch failed" false
    echo "#! $(which bash)" > /etc/update-motd.d/motd
    echo "echo 'GENERAL INFORMATION'" >> /etc/update-motd.d/motd
    echo "$(which screenfetch)" >> /etc/update-motd.d/motd
    run "$(chmod -x /etc/update-motd.d/*)" "Changed Permission to files" "Change permission to files failed" false
    run "$(chmod +x /etc/update-motd.d/motd)" "Added execute permission to motd" "Add execute permission to motd failed" false
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
                            run "$(fallocate -l ${SWAPSIZE}G /swapfile 2>>$ERRORFILE)" "Fallocated" "Fallocated failed" true
                            run "$(dd if=/dev/zero of=/swapfile bs=1024 count=$((1048576 * SWAPSIZE)) 2>>$ERRORFILE)" "dd for swapfile" "dd failed" true
                            run "$(chmod 600 /swapfile 2>>$ERRORFILE)" "Locked swap location" "Locking swap location failed" true
                            run "$(mkswap /swapfile 2>>$ERRORFILE)" "Created swap" "Create swap failed" true
                            run "$(swapon /swapfile 2>>$ERRORFILE)" "Enabled swap" "Enable swap failed" true
                            run "$(echo "/swapfile swap swap defaults 0 0" >> /etc/fstab)" "Added swap at system start" "Add swap to system start failed" false
                            run "$(mount -a 2>>$ERRORFILE)" "Mounted swap" "Mount swap failed" false
                            showresult "Swap is setted to $SWAPSIZE GB" 
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
                echo "Updating server ..."
                run "$(apt update -y 2>>$ERRORFILE)" "Updated Server" "Update Server failed" true
                echo "Upgrading server, this will take minutes or hours ..."
                run "$(apt upgrade -y 2>>$ERRORFILE)" "Upgraded server" "Upgrade Server Failed" true
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
                run "$(hostnamectl set-hostname $HOSTNAME 2>>$ERRORFILE)" "Setted hostname to $HOSTNAME" "Set hostname failed" false
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
                run "$(timedatectl set-timezone $TIMEZONE 2>>$ERRORFILE)" "Setted timezone to $TIMEZONE" "Set timezone failed" false
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
                run "$(apt install -y zip unzip 2>>$ERRORFILE)" "Installed zip/unzip" "Install zip/unzip failed" true
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
                    run "$(apt install -y ufw)" "Installed UFW Firewall" "Install UFW failed" true
                fi
                while true;
                do
                    echo "This might interupt server connection please be sure."
                    echo "Options: [Type 'SHOW' 'ALLOW' 'DENY' 'ENABLE' 'DISABLE' 'DEFAULT' 'EXIT']"
                    read -p "Do you want to Allow oer Deny Enable Disable Firewall now?: " UFWSETTINGS
                    case $UFWSETTINGS in
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
                run "$(echo "deb https://download.webmin.com/download/repository sarge contrib" >> /etc/apt/sources.list)" "Added webmin repository" "Add webmin repository failed" true
                run "$(wget https://download.webmin.com/jcameron-key.asc 2>>$ERRORFILE)" "Downloaded jcameron-key" "Download jcameron-key failed" true
                run "$(apt-key add jcameron-key.asc 2>> $ERRORFILE)" "Added jcameron-key to system" "Add jcameron-key failed" true
                run "$(apt-get install apt-transport-https 2>>$ERRORFILE)" "Installed apt-transport-https" "Install apt-transport-htps failed" true 
                run "$(apt-get -y update  2>> $ERRORFILE)" "Updated server" "Update server failed" true
                run "$(apt-get install webmin 2>>$ERRORFILE)" "Installed webmin" "Install webmin failed" true
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
                run "$(bash <(curl -Ss https://my-netdata.io/kickstart.sh))" "Installed NetData" "Install Netdata failed" true
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
showresult "Database mysql installation secured"
}


function InstallMariadb
{
    display "Install MariaDB"
    while true;
    do
        read -p "Install Mariadb Server Now? [Y/N]: " MDB
        case $MDB in 
            [yY]|[yY][eE][sS])
                run "$(apt install -y mariadb-server  2>>$ERRORFILE)" "Installed Mariadb-server" "Install Mariadb failed" true
                showresult "MariaDB installed"
                securemysql
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
    run "$(curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar 2>>$ERRORFILE)" "Downloaded wpcli" "Download wpcli failed" true
    run "$(chmod +x wp-cli.phar 2>>$ERRORFILE)" "Added execute permission to wpcli" "Add execute permission to wpcli failed" true
    run "$(mv wp-cli.phar /usr/local/bin/wp 2>>$ERRORFILE)" "Moved file for all users" "Move file to all users failed" true
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
                run "$(wget https://wordpress.org/latest.zip 2>>$ERRORFILE)" "Downloaded wordpress" "Download wordpress failed" true
                run "$(unzip latest.zip 2>>$ERRORFILE)" "Extracted wordpress" "Extract wordpress failed" true
                run "$(chown -R www-data:www-data wordpress 2>>$ERRORFILE)" "Changed wordpress folder owner" "Change wordpress folder owner failed" true
                run "$(rm latest.zip 2>>$ERRORFILE)" "Removed archive file" "Remove archive file failed" true
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
                InstallMariadb 
                run "$(apt-get install -y php php-mysql php-zip php-curl php-gd php-mbstring php-xml php-xmlrpc 2>>$ERRORFILE)" "Installed Apache2" "Install Apache2 failed" true
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
    run "$(curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar 2>>$ERRORFILE)" "Downloaded wpcli" "Download wpcli failed" true
    run "$(chmod +x wp-cli.phar 2>>$ERRORFILE)" "Added execute permission to wpcli" "Add execute permission to wpcli failed" true
    run "$(mv wp-cli.phar /usr/local/bin/wp 2>>$ERRORFILE)" "Moved file for all users" "Move file to all users failed" true
    run "$(cp /usr/local/lsws/lsphp74/bin/php /usr/bin/ 2>>$ERRORFILE)" "Copied php" "Copy php failed" true
    showresult "WP-CLI for Apache Installed"
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
                run "$(wget https://wordpress.org/latest.zip 2>>$ERRORFILE)" "Downloaded wordpress" "Download wordpress failed" true
                run "$(unzip latest.zip 2>>$ERRORFILE)" "Extracted wordpress" "Extract wordpress failed" true
                run "$(chown -R nobody:nogroup wordpress 2>>$ERRORFILE)" "Changed wordpress folder owner" "Change wordpress folder owner failed" true
                run "$(rm latest.zip 2>>$ERRORFILE)" "Removed archive file" "Remove archive file failed" true
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
                run "$(wget --no-check-certificate https://raw.githubusercontent.com/litespeedtech/ols1clk/master/ols1clk.sh && bash ols1clk.sh 2>>$ERRORFILE)" "Downloaded and installed Openlitespeed" "Download and install Openlitespeed failed" true
                run "$(apt-get install -y lsphp73 lsphp73-curl lsphp73-imap lsphp73-mysql lsphp73-intl lsphp73-pgsql lsphp73-sqlite3 lsphp73-tidy lsphp73-snmp lsphp73-json lsphp73-common lsphp73-ioncube 2>>$ERRORFILE)" "Installed PHP73" "Install PHP73 failed" true
                run "$(rm ols1clk.sh 2>>$ERRORFILE)" "Removed Openlitespeed installation script" "Remove Openlitespeed installation script failed" true
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
                if [ $(crontab -l) -eq 0 ]
                then
                    crontab -l > mycron 2>>$ERRORFILE
                fi
                
                #echo new cron into cron file
                run "$(echo "30 3 * * * shutdown -r now" >> mycron)" "Added new cron file" "Add new cron file failed" true
                #install new cron file
                run "$(crontab mycron 2>>$ERRORFILE)" "Applied cron file to cron" "Apply cron file to cron failed" true
                run "$(rm mycron 2>>$ERRORFILE)" "Remove cron file" "Remove cron file failed" true
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
    initialize
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
        echo "   X)         EXIT Script"
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
                initialize
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