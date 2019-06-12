#!/bin/bash
#
# The script will dump UFM mysql database and UFM configuration files 
# 
# March 2011

VERSION=1.0
STATUS=1
VERSION=`rpm -qa | grep ufm-`
DATE=`date +%F-%H_%M_%S`
DUMPDIR="/tmp/ufmdump"
DUMPFILE="$DUMPDIR/mysqldump__"$VERSION"__"$DATE
UFM_CONFDIR="/opt/ufm/files/conf/"
UFM_BACKUPFILE=$DUMPDIR/ufm_backup__"$VERSION"__"$DATE".tar.gz

mkdir -p $DUMPDIR

mysqldump --defaults-file=/opt/ufm/conf/my.cnf --all-databases > $DUMPFILE

STATUS=${?}

if  [ $STATUS -ne 0 ] ; then 
	echo "UFM mysql dump was failed."
	exit 1
fi

tar zcf $UFM_BACKUPFILE $DUMPFILE $UFM_CONFDIR

echo "UFM configuration was dump to $UFM_BACKUPFILE" 

exit 0

