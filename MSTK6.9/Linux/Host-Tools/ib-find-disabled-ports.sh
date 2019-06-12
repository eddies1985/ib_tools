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
# This script will report all the disabled ports in the IB fabric  
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

echo_red ()
{
echo -e "\\033[1;031m"$1"\\033[0;39m"
return 0
}

checked_ports=0
count_disabled=0

FILE="/tmp/temp.$$"

echo ""
echo $MyName "Version" $VERSION
echo ""

$IBPATH/ibnetdiscover -p | grep -v \( | grep -e "^SW" > $FILE

exec < $FILE
while read LINE
do

PORT="`echo $LINE |awk '{print $(3)}'`"
GUID="`echo $LINE |awk '{print $(4)}'`"
LID="`echo $LINE |awk '{print $(2)}'`"

checked_ports=$((checked_ports+1))
LINK_STATE="`$IBPATH/ibportstate -G $GUID $PORT | grep PhysLinkState | head -1 | sed 's/.\.\.\./ /g' | awk '{print $NF}'`"
Switch_ND="`$IBPATH/smpquery nd -G $GUID |sed 's/Node Description:[.]*[.]/ /g'`"


if [ "$LINK_STATE" == "Disabled" ] ; then
	$IBPATH/ibswitches | grep $GUID | grep -q sRB-20210G-1UP
	if [ $? == 0 -a $PORT == 24 ] ; then
		Is_10G=1
	else
		count_disabled=$((count_disabled + 1))
		echo_red "Switch: $Switch_ND LID $LID Guid $GUID PORT: $PORT is disabled"
	fi
fi

done

rm -f /tmp/temp.$$

echo ""
echo "## Summary: $checked_ports ports checked, $count_disabled disabled ports found" 
