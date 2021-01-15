#! /bin/bash
if (( $EUID != 0 )); then
    echo "Please run as root"
    exit
fi
RESULTFILE="result.txt"
CURDIR=$PWD
MESSAGE=""
function display
{
    HLINE="********************************************************************************"
    EMPTYLINE="*                                                                              *"
    echo "$HLINE"
    echo "$EMPTYLINE"
    echo "$EMPTYLINE"
    echo "               $MESSAGE                   "
    echo "$EMPTYLINE"
    echo "$EMPTYLINE"
    echo "$HLINE"
}
function installswap
{
    clear
    MESSAGE="Installing Swap ..."
    display
    while true;
    do
        read -p "Install Swap Size in GB: " SWAPSIZE
        case $SWAPSIZE in [1]|[2]|[3]|[4]|[5]|[6]|[7]|[8]|[9])
                echo "Configuring Swap ..."
                fallocate -l ${SWAPSIZE}G /swapfile
                dd if=/dev/zero of=/swapfile bs=1024 count=$((1048576 * SWAPSIZE))
                chmod 600 /swapfile
                mkswap /swapfile
                swapon /swapfile
                echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
                mount -a
                echo "Swap is setted to $SWAPSIZE GB" >> $RESULTFILE
                echo "Swap is setted to $SWAPSIZE GB"
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
    MESSAGE="Install Swap"
    display
    while true;
    do
        read -p "Unpdate and Upgrade Server Now? (Y/N): " UP
        case $UP in 
            [yY]|[yY][eE][sS])
                apt update
                apt Upgrade -y
                echo "Update, Upgrade Done"
                echo "Update, Upgrade Done" >> $RESULTFILE
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
    MESSAGE="Set Host name"
    display
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
                hostnamectl set-hostname $HOSTNAME
                echo "Host Name Setted to $HOSTNAME"
                echo "Host Name Setted to $HOSTNAME" >> $RESULTFILE
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
    MESSAGE="Configure Time Zone"
    display
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
                timedatectl set-timezone $TIMEZONE
                echo "Timezone Setted to $TIMEZONE"
                echo "Timezone Setted to $TIMEZONE" >> $RESULTFILE
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
    MESSAGE="Install Zip/Unzip"
    display
    while true;
    do
        read -p "Install Zip and Unzip Now? (Y/N): " ZIP
        case $ZIP in 
            [yY]|[yY][eE][sS])
                apt install -y zip unzip
                echo "Zip/Unzip Installed" >> $RESULTFILE
                echo "Zip/Unzip Installed"
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
    MESSAGE="Install MariaDB"
    display
    while true;
    do
        read -p "Install Mariadb Server Now? (Y/N): " MDB
        case $MDB in 
            [yY]|[yY][eE][sS])
                apt install -y mariadb-server 
                mysql_secure_installation
                echo "MariaDB installed"
                echo "MariaDB installed" >> $RESULTFILE
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
    MESSAGE=$'Wordpress for Apache Server \n This will install Following \n    - wordpress \n     - wp-cli'
    display
    while true;
    do
        read -p "Install Wordpress Now? (Y/N): " WPAPCHE
        case $WPAPCHE in 
            [yY]|[yY][eE][sS])
                SITELOC=/var/www/html
                mkdir $SITELOC
                cd $SITELOC
                wget https://wordpress.org/latest.zip
                unzip latest.zip
                chown -R www-data:www-data wordpress
                rm latest.zip
                curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
                chmod +x wp-cli.phar
                mv wp-cli.phar /usr/local/bin/wp
                cd $CURDIR
                echo "Wordpress and wp-cli Installed at $SITELOC"
                echo "Wordpress and wp-cli Installed at $SITELOC" >> $RESULTFILE
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
    MESSAGE="Install Apache Virtual Server"
    display
    while true;
    do
        read -p "Install Apache Web Server Now? (Y/N): " APCHE
        case $APCHE in 
            [yY]|[yY][eE][sS])
                InstallMariadb
                apt-get install -y php php-mysql php-zip php-curl php-gd php-mbstring php-xml php-xmlrpc
                echo "Apache installed"
                echo "Apache installed" >> $RESULTFILE
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
    MESSAGE=$' Wordpress for OpenLiteSpeed Server \n This will install Following \n    - wordpress \n     - wp-cli'
    display
    while true;
    do
        read -p "Install Wordpress Now? (Y/N): " WPOLS
        case $WPOLS in 
            [yY]|[yY][eE][sS])
                SITELOC=/usr/local/lsws/sites
                mkdir $SITELOC
                cd $SITELOC
                wget https://wordpress.org/latest.zip
                unzip latest.zip
                chown -R nobody:nogroup wordpress
                rm latest.zip
                curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
                chmod +x wp-cli.phar
                mv wp-cli.phar /usr/local/bin/wp
                cp /usr/local/lsws/lsphp74/bin/php /usr/bin/
                cd $CURDIR
                echo "Wordpress and wp-cli Installed at $SITELOC" >> $RESULTFILE
                echo "Wordpress and wp-cli Installed at $SITELOC"
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
    MESSAGE="Installing OpenLiteSpeed Virtual Server"
    display
    while true;
    do
        read -p "Install OpenLiteSpeed Web Server Now? (Y/N): " OLS
        case $OLS in 
            [yY]|[yY][eE][sS])
                InstallMariadb
                wget --no-check-certificate https://raw.githubusercontent.com/litespeedtech/ols1clk/master/ols1clk.sh && bash ols1clk.sh
                apt-get install -y lsphp73 lsphp73-curl lsphp73-imap lsphp73-mysql lsphp73-intl lsphp73-pgsql lsphp73-sqlite3 lsphp73-tidy lsphp73-snmp lsphp73-json lsphp73-common lsphp73-ioncube
                rm ols1clk.sh
                echo "OpenLiteSpeed installed"
                echo "OpenLiteSpeed installed" >> $RESULTFILE
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
    MESSAGE="Install Server Cron Schedule"
    display
    while true;
    do
        read -p "Install reset cron schedule Now? (Y/N): " CRON
        case $CRON in 
            [yY]|[yY][eE][sS])
                crontab -l > mycron
                #echo new cron into cron file
                echo "30 3 * * * shutdown -r now" >> mycron
                #install new cron file
                crontab mycron
                rm mycron
                echo "Cron Installed" >> $RESULTFILE
                echo "Cron Installed"
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
    Message="Select Vertual Host Server Type"
    display
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
    Message="Install Web Server"
    display
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

echo
echo
MESSAGE="ALL DONE!  LOOK THE RESULT SUMMARY BELOW"
display
cat $RESULTFILE
