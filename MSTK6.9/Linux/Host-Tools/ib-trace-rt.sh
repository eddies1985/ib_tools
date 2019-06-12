#!/bin/bash
#
# Copyright (C) Mellanox Ltd. 2001-2014.  ALL RIGHTS RESERVED.
#
# This software product is a proprietary product of Mellanox Ltd.
# (the "Company") and all right, title, and interest and to the software product,
# including all associated intellectual property rights, are and shall
# remain exclusively with the Company.
#
# This software product is governed by the End User License Agreement
# provided with the software product.
#

VERSION=6.0
MyName=`basename $0`
HOST=$(hostname)
XDATE=$(date +%Y%m%d-%H%M)
IBPATH=${IBPATH:-/usr/sbin}
export LC_ALL=POSIX

echo ""
echo $MyName "Version" $VERSION
echo ""

IBPATH=${IBPATH:-/usr/sbin}

function usage() {
        echo "Usage: `basename $0` <src-hostname> <dest-hostname>"
        exit -1
}

[ $# -ne 2 ] && usage 

SRC=$1 
DEST=$2

SRC_LID=`$IBPATH/ibnetdiscover -p | egrep ^CA | grep $SRC | awk '{ print $2}' | head -1`
DEST_LID=`$IBPATH/ibnetdiscover -p | egrep ^CA | grep $DEST | awk '{ print $2}' | head -1`

if [ -z $SRC_LID ] ; then
	echo "can't find $SRC"
	exit
fi

if [ -z $DEST_LID ] ; then
	echo "can't find $DEST"
	exit
fi

$IBPATH/ibtracert $SRC_LID $DEST_LID
