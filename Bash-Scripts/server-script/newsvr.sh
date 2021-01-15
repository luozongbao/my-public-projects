#! /bin/bash
if (( $EUID != 0 )); then
    echo "Please run as root"
    exit
fi
UpdateUpgrade
installswap
ConfigTimeZone
InstallZipUnzip
InstallWebServer

function installswap
{
    clear
    while true;
    do
        echo "Installing Swap"
        echo 
        read -p "Install Swap Size in GB" SWAPSIZE
        case $SWAPSIZE in [1]|[2]|[3]|[4]|[5]|[6]|[7]|[8]|[9])
                echo "Install Swap"
                fallocate -l ${SWAPSIZE}G /swapfile
                dd if=/dev/zero of=/swapfile bs=1024 count=$((1048576 * SWAPSIZE))
                chmod 600 /swapfile
                mkswap /swapfile
                swapon /swapfile
                echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
                mount -a
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
    echo "Update and Upgrade Server"
    while true;
    do
        read -p "Unpdate and Upgrade Server Now?" UP
        case $UP in 
            [yY]|[yY][eE][sS])
                echo "Install Swap"
                apt update
                apt Upgrade -y
                echo "Update, Upgrade Done"
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
    echo "Configure TimeZone"
    while true;
    do
        read -p "Congfigure Timezone?" TZ
        case $TZ in 
            [yY]|[yY][eE][sS])
                timedatectl set-timezone Asia/Bangkok
                echo "Timezone Setted"
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
    echo "Install Zip/Unzip"
    while true;
    do
        read -p "Install Zip and Unzip Now?" ZIP
        case $ZIP in 
            [yY]|[yY][eE][sS])
                echo "Install Zip"
                apt install -y zip unzip
                echo "Done"
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
    echo "Install Mariadb"
    while true;
    do
        read -p "Mariadb Server Now?" MDB
        case $MDB in 
            [yY]|[yY][eE][sS])
                apt install -y mariadb-server 
                mysql_secure_installation
                echo "MariaDB installed"
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
    echo "Wordpress for Apache Server"
    echo "This will install Following"
    echo "   - wordpress"
    echo "   - wp-cli"
    while true;
    do
        read -p "Install Wordpress Now?" WS
        case $WS in 
            [yY]|[yY][eE][sS])
                wget https://wordpress.org/latest.zip
                unzip latest.zip
                chown -R www-data:www-data wordpress
                rm latest.zip
                curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
                chmod +x wp-cli.phar
                mv wp-cli.phar /uer/local/bin/wp
                echo 'Wordpress and wp-cli Installed'
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
    echo "Install Apache Web Server"
    while true;
    do
        read -p "Install Apache Web Server Now?" APCHE
        case $APCHE in 
            [yY]|[yY][eE][sS])
                InstallMariadb
                apt-get install -y php php-mysql php-zip php-curl php-gd php-mbstring php-xml php-xmlrpc
                echo "Apache installed"
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
    echo "Wordpress OpenLitespeed Server"
    echo "This will install Following"
    echo "   - wordpress"
    echo "   - wp-cli"
    while true;
    do
        read -p "Install Wordpress Now?" WS
        case $WS in 
            [yY]|[yY][eE][sS])
                wget https://wordpress.org/latest.zip
                unzip latest.zip
                chown -R nobody:nogroup wordpress
                rm latest.zip
                curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
                chmod +x wp-cli.phar
                mv wp-cli.phar /uer/local/bin/wp
                cp /usr/local/lsws/lsphp74/bin/php /usr/bin/
                echo 'Wordpress and wp-cli Installed'
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
    echo "Install OpenLiteSpeed Web Server"
    while true;
    do
        read -p "Install OpenLiteSpeed Web Server Now?" OLS
        case $OLS in 
            [yY]|[yY][eE][sS])
                InstallMariadb
                wget --no-check-certificate https://raw.githubusercontent.com/litespeedtech/ols1clk/master/ols1clk.sh && bash ols1clk.sh
                apt-get install -y lsphp73 lsphp73-curl lsphp73-imap lsphp73-mysql lsphp73-intl lsphp73-pgsql lsphp73-sqlite3 lsphp73-tidy lsphp73-snmp lsphp73-json lsphp73-common lsphp73-ioncube
                echo "OpenLiteSpeed installed"
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
    echo "Install Server Cron Schedule"
    while true;
    do
        read -p "Install reset cron Now?" CRON
        case $CRON in 
            [yY]|[yY][eE][sS])
                crontab -l > mycron
                #echo new cron into cron file
                echo "30 3 * * * shutdown -r now" >> mycron
                #install new cron file
                crontab mycron
                rm mycron
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
    echo "Select Vertual Host Server Type"
    while true;
    do
        read -p "Install Apache Or OpenLiteSpeed?" AOC
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
    echo "Install Web Server"
    while true;
    do
        read -p "Install Web Server Now?" WS
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