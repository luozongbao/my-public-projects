#! /bin/bash
###################################################################
# Script Name	: New Server                                                                                             
# Description	: To be run on new server                                                                      
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
CURDIR=$PWD

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

function installswap
{
    clear
    display "Installing Swap ..."
    while true;
    do
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
                read -p "Press Enter to continue: " ENTER
                break
                ;;
            *) 
                echo "Please, identify 1-9"
            ;;
        esac
    done
}

function UpdateUpgrade
{
    clear
    display"Update and Upgrade Server"
    while true;
    do
        read -p "Unpdate and Upgrade Server Now? (Y/N): " UP
        case $UP in 
            [yY]|[yY][eE][sS])
                apt update 2>>$ERRORFILE
                apt upgrade -y 2>>$ERRORFILE
                showresult "Update, Upgrade Done" 
                read -p "Press Enter to continue: " ENTER
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
    clear
    display "Set Host name"
    while true;
    do
        read -p "Congfigure HostName? (Y/N): " HN
        case $HN in 
            [yY]|[yY][eE][sS])
                read -p "What is your Host Name (HostName): " HOSTNAME
                if [ -z $HOSTNAME ] 
                then 
                    HOSTNAME=HostName 
                fi
                hostnamectl set-hostname $HOSTNAME 2>>$ERRORFILE
                showresult "Host Name Setted to $HOSTNAME"
                read -p "Press Enter to continue: " ENTER
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
    clear
    display"Configure Time Zone"
    while true;
    do
        read -p "Congfigure Timezone? (Y/N): " TZ
        case $TZ in 
            [yY]|[yY][eE][sS])
                read -p "What Time Zone (Asia/Bangkok): " TIMEZONE
                if [ -z $TIMEZONE ] 
                then 
                    TIMEZONE=Asia/Bangkok 
                fi
                timedatectl set-timezone $TIMEZONE 2>>$ERRORFILE
                showresult "Timezone Setted to $TIMEZONE"
                read -p "Press Enter to continue: " ENTER
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
    clear
    display "Install Zip/Unzip"
    while true;
    do
        read -p "Install Zip and Unzip Now? (Y/N): " ZIP
        case $ZIP in 
            [yY]|[yY][eE][sS])
                apt install -y zip unzip 2>>$ERRORFILE
                showresult "Zip/Unzip Installed"
                read -p "Press Enter to continue: " ENTER
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

function InstallMariadb
{
    clear
    display "Install MariaDB"
    while true;
    do
        read -p "Install Mariadb Server Now? (Y/N): " MDB
        case $MDB in 
            [yY]|[yY][eE][sS])
                apt install -y mariadb-server  2>>$ERRORFILE
                mysql_secure_installation 2>>$ERRORFILE
                showresult "MariaDB installed"
                read -p "Press Enter to continue: " ENTER
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

function InstallWordpressApache
{
    clear
    display $'Wordpress for Apache Server \n This will install Following \n    - wordpress \n     - wp-cli'
    while true;
    do
        read -p "Install Wordpress Now? (Y/N): " WPAPCHE
        case $WPAPCHE in 
            [yY]|[yY][eE][sS])
                SITELOC=/var/www/html
                mkdir $SITELOC 2>>$ERRORFILE
                cd $SITELOC 2>>$ERRORFILE
                wget https://wordpress.org/latest.zip 2>>$ERRORFILE
                unzip latest.zip 2>>$ERRORFILE
                chown -R www-data:www-data wordpress 2>>$ERRORFILE
                rm latest.zip 2>>$ERRORFILE
                curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar 2>>$ERRORFILE
                chmod +x wp-cli.phar 2>>$ERRORFILE
                mv wp-cli.phar /usr/local/bin/wp 2>>$ERRORFILE
                cd $CURDIR
                showresult "Wordpress and wp-cli Installed at $SITELOC"
                read -p "Press Enter to continue: " ENTER
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
    clear
    display "Install Apache Virtual Server"
    while true;
    do
        read -p "Install Apache Web Server Now? (Y/N): " APCHE
        case $APCHE in 
            [yY]|[yY][eE][sS])
                InstallMariadb 2>>$ERRORFILE
                apt-get install -y php php-mysql php-zip php-curl php-gd php-mbstring php-xml php-xmlrpc 2>>$ERRORFILE
                showresult "Apache installed"
                read -p "Press Enter to continue: " ENTER
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

function InstallWordpressOLS
{
    clear
    display $' Wordpress for OpenLiteSpeed Server \n This will install Following \n    - wordpress \n     - wp-cli'
    while true;
    do
        read -p "Install Wordpress Now? (Y/N): " WPOLS
        case $WPOLS in 
            [yY]|[yY][eE][sS])
                SITELOC=/usr/local/lsws/sites
                mkdir $SITELOC 2>>$ERRORFILE
                cd $SITELOC 2>>$ERRORFILE
                wget https://wordpress.org/latest.zip 2>>$ERRORFILE
                unzip latest.zip 2>>$ERRORFILE
                chown -R nobody:nogroup wordpress 2>>$ERRORFILE
                rm latest.zip 2>>$ERRORFILE
                curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar 2>>$ERRORFILE
                chmod +x wp-cli.phar 2>>$ERRORFILE
                mv wp-cli.phar /usr/local/bin/wp 2>>$ERRORFILE
                cp /usr/local/lsws/lsphp74/bin/php /usr/bin/ 2>>$ERRORFILE
                cd $CURDIR
                showresult "Wordpress and wp-cli Installed at $SITELOC"
                read -p "Press Enter to continue: " ENTER
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
    clear
    display "Installing OpenLiteSpeed Virtual Server"
    while true;
    do
        read -p "Install OpenLiteSpeed Web Server Now? (Y/N): " OLS
        case $OLS in 
            [yY]|[yY][eE][sS])
                InstallMariadb
                wget --no-check-certificate https://raw.githubusercontent.com/litespeedtech/ols1clk/master/ols1clk.sh && bash ols1clk.sh 2>>$ERRORFILE
                apt-get install -y lsphp73 lsphp73-curl lsphp73-imap lsphp73-mysql lsphp73-intl lsphp73-pgsql lsphp73-sqlite3 lsphp73-tidy lsphp73-snmp lsphp73-json lsphp73-common lsphp73-ioncube 2>>$ERRORFILE
                rm ols1clk.sh 2>>$ERRORFILE
                showresult "OpenLiteSpeed installed"
                cat /usr/local/lsws/password >> $RESULTFILE
                read -p "Press Enter to continue: " ENTER
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
    clear
    display "Install Server Cron Schedule"
    while true;
    do
        read -p "Install reset cron schedule Now? (Y/N): " CRON
        case $CRON in 
            [yY]|[yY][eE][sS])
                crontab -l > mycron 2>>$ERRORFILE
                #echo new cron into cron file
                echo "30 3 * * * shutdown -r now" >> mycron
                #install new cron file
                crontab mycron 2>>$ERRORFILE
                rm mycron 2>>$ERRORFILE
                showresult "Cron Installed"
                read -p "Press Enter to continue: " ENTER
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
    clear
    display "Select Vertual Host Server Type"
    while true;
    do
        read -p "Select your virtual host server 'Apache' Or 'OpenLiteSpeed'? (A/O/C)" AOC
        case $AOC in 
            [aA]|[aA][pP][aA][cC][hH][eE])
                InstallApache
                InstallCron
                break
                ;;
            [oO]|[oO][pP][eE][nN][lL][iI][tT][eE][sS][pP][eE][eE][dD])
                InstallOpenLiteSpeed
                InstallCron
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
    clear
    display "Install Web Server"
    while true;
    do
        read -p "Do you want to install Web Server Now? (Y/N): " WS
        case $WS in 
            [yY]|[yY][eE][sS])
                SelectVirtualHostServer
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

UpdateUpgrade
installswap
ConfigTimeZone
ConfigHostName
InstallZipUnzip
InstallWebServer
read -p "Press Enter to continue: " ENTER
clear
echo
echo
showresult " ----==== ALL DONE ====----" 
cat $RESULTFILE
echo "***************** WP INFO *****************"
wp --info