#! /bin/bash
if (( $EUID != 0 )); then
    echo "Please run as root"
    exit
fi
read -p "Please input the website File Directory: " FILEDIR
read -p "Please input the website database name: " DBNAME
FILELOC=/usr/local/lsws/sites

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
                                rm -r $FILELOC/$FILEDIR
                                echo "$FILELOC/$FILEDIR removed."
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
else
        echo "DIrectory $FILELOC/$FILEDIR not found."
        exit 1
fi

while true;
do
        read -p "This will remove database $DBNAME permanently (Y/N): " YN
        case $YN in
                [yY]|[yY][eE][sS])
                        mysql -u root -e "DROP DATABASE $DBNAME;"
                        echo "$DBNAME removed"
                        break
                        ;;
                [nN]|[nN][oO])
                        echo "skipping remove database $DBNAME"
                        break
                        ;;
                *)
                        echo "Please answer Y/N"
                        ;;
        esac
done
