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
FILELOC=/usr/local/lsws/sites
WPDIR=""

RESULTFILE="$CURDIR/result.txt"
ERRORFILE="$CURDIR/error.txt"


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
    display "Collect information before "
    read -p "Please, identify wordpress directory" WPDIR
}

function getreadyenvironment
{
    cd $FILELOC/$WPDIR
    wp --info
}

function discourageSearchEnging
{
    display "Start defining test website"
    wp option set blog_public 0 2>> $ERRORFILE
    result "Discourage search engines from indexing the site"
}

function disablePlugins
{
    while true;
    do
        echo " List Plugins and status "
        sudo wp plugin list --allow-root
        echo
        read -p "type plugin name to disable.  Type DONE to exit" PLUGIN
        if [ "$PLUGIN" == "DONE" ]
        then
                break
        else
                showresult $(wp plugin deactivate $PLUGIN --allow-root 2>> $ERRORFILE)
        fi
    done
}

clear
getInformation
getreadyenvironment
discourageSearchEnging
disablePlugins
cat $RESULTFILE


