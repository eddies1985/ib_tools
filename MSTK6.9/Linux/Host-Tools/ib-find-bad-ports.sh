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
#
# This script will look for bad ports in the IB fabric
# Bad ports are all 1X ports and degraded links (for eample DDR link which came as SDR) 
#
# As prerequisite, the infiniband diagnostic tools rpm (infiniband-diags) must be installed 
#
# Written by Yair Goldel <yairg@mellanox.com>
# 
# May 2009

VERSION=6.0
MyName=`basename $0`
HOST=$(hostname)
XDATE=$(date +%Y%m%d-%H%M)
IBPATH=${IBPATH:-/usr/sbin}
export LC_ALL=POSIX

echo ""
echo $MyName "Version" $VERSION
echo ""

LIST=0
SPEED=1
WIDTH=1
RESET=0



echo_red ()
{
echo -e "\\033[1;031m"$1"\\033[0;39m"
return 0
}

echo_green ()
{
echo -e "\\033[1;032m"$1"\\033[0;39m"
return 0
}

abort_function() {
        if [[ "XXX$*" != "XXX" ]] ; then
                echo_red "$*"
        fi
        exit 1
}

trap 'abort_function "CTRL-C hit. Aborting."' 2


count_1x=0
checked_ports=0
count_deg=0

FILE="/tmp/temp.$$"
TEMPFILE="/tmp/tempportinfo.$$"


echo -en "Looking For Degraded Width (1X) Links .......\t"
echo_green "done "
echo -en "Looking For Degraded Speed Links ............\t"

$IBPATH/ibnetdiscover -p | grep \( | grep -e "^SW" > $FILE

exec < $FILE
while read LINE
do

checked_ports=$((checked_ports+1))

PORT="`echo $LINE |awk '{print $(3)}'`"
GUID="`echo $LINE |awk '{print $(4)}'`"

$IBPATH/ibportstate -G $GUID $PORT > $TEMPFILE

ACTIVE_WIDTH="`cat $TEMPFILE | grep LinkWidthActive | head -1 | sed 's/.\.\./ /g' | awk '{print $(NF)}'`"
ACTIVE_SPEED="`cat $TEMPFILE | grep LinkSpeedActive | head -1 | sed 's/.\.\./ /g' | awk '{print $2}'`"
ENABLE_SPEED="`cat $TEMPFILE | grep LinkSpeedEnabled |head -1| sed 's/\.\./ /g' | awk '{print $(NF-1)}'`"

if [ "$ACTIVE_WIDTH" == "1X" ] ; then
	count_1x=$((count_1x + 1))
	echo_red "GUID:$GUID PORT:$PORT run in 1X width"
fi

if [ "$ACTIVE_SPEED" != "$ENABLE_SPEED" ] ; then

	PEER_ENABLE_SPEED="`cat $TEMPFILE  | grep LinkSpeedEnabled |tail -1| sed 's/\.\./ /g' | awk '{print $(NF-1)}'`"

	if [ "$ACTIVE_SPEED" != "$PEER_ENABLE_SPEED" ] ; then

		count_deg=$((count_deg+1))
		echo_red "GUID:$GUID PORT:$PORT run in degraded speed"
		#ibportstate -G $GUID $PORT reset >/dev/null 2>&1
        	#ibportstate -G $GUID $PORT enable >/dev/null 2>&1
	fi
fi

done

CHECKED=$checked_ports
rm -f $FILE $TEMPFILE

echo_green "done "
echo ""

echo ""
echo "## Summary: $CHECKED ports checked" 
echo "##	  $count_1x ports with 1x width found "
echo "##        $count_deg ports with degraded speed found "
