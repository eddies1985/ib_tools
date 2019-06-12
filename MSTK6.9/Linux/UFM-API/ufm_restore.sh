#!/bin/bash
#
# The script will restore UFM mysql database and configurations 
# 
# March 2011

VERSION=1.0
STATUS=1
#VERSION=`rpm -qa | grep ufm-`
#DATE=`date +%F-%H_%M_%S`
#DUMPDIR="/tmp/ufmdump"
DUMPFILE=""
#UFM_CONFDIR="/opt/ufm/files/conf/"
#UFM_BACKUPFILE=$DUMPDIR/ufm_backup__"$VERSION"__"$DATE".tar.gz

#mkdir -p $DUMPDIR

function usage (){
 	echo Usage: `basename $0` " -f UFM_DUMP_FILE [-v] [-h]"
        echo ""
        exit 1
}



# No option is given
[ $# -eq 0 ] && usage

while getopts f:hv opt; do
        case $opt in
        f)
                DUMPFILE=$OPTARG
                ;;
        v)
                echo "`basename $0` version $VERSION"
                exit
                ;;
        h)
                usage
                ;;

        *)
                usage
                ;;
        esac
done


/usr/bin/ufmysql < $DUMPFILE

STATUS=${?}

if  [ $STATUS -ne 0 ] ; then 
	echo "UFM mysql restore was failed."
	exit 1
fi


echo "UFM database was restored, please restart UFM [ /etc/init.d/ufmd restart ]" 

exit 0

