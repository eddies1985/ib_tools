#!/bin/bash
##
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
#
#
#
# This script will list all SM in the IB fabric  
#
# As prerequisite, the infiniband diagnostic tools rpm (infiniband-diags) must be installed 
#
# Written by Yair Goldel <yairg@mellanox.com>
# 
# June 2009


VERSION=6.0
MyName=`basename $0`
HOST=$(hostname)
XDATE=$(date +%Y%m%d-%H%M)
IBPATH=${IBPATH:-/usr/sbin}
export LC_ALL=POSIX

echo ""
echo $MyName "Version" $VERSION
echo ""


echo_red ()
{
echo -e "\\033[1;031m"$1"\\033[0;39m"
return 0
}

echo ""
for lid in `$IBPATH/saquery -s | grep "EndPortLid" | sed 's/\.\./ /g' | awk '{print $(NF)}'` ; do
	
	f=`$IBPATH/smpquery nodedesc $lid | sed -e 's/^Node Description:\.*\(.*\)/\1/'`

	echo $f | grep -q "sFB-"
	if [ $? == 1 ] ; then
		# SM found on 4XXX or OFED server
		echo -en "SM found on:\t"
		echo_red "$f"
	else
		# SM found on 2XXX or 9XXX
		#g=`ibaddr $lid | awk '{print $2}' | awk -F: '{print $NF}'`
		g=`ibaddr $lid | awk '{a=substr($2,18); printf ("%s", a)}'`

		echo -en "SM found on:\t"
		echo_red "`saquery -S | grep -A 34 $g |awk '/ServiceData32.4/{a=substr($1,27);next} /ServiceData64.1/{b=substr($1,27);next} /ServiceData64.2/{c=substr($1,27); name=sprintf("%s%s%s", a,b,c); for(i=1;i<=length(name);i=i+2) {c="0x"substr(name,i,2); printf("%c",strtonum(c))} print "\n"}'`"

	fi
done

echo ""
echo -en "The master SM is running on:\t"
master_lid=`$IBPATH/saquery -s | grep master_sm_base_lid | uniq  | sed 's/\.\./ /g' | awk '{print $(NF)}'`
f=`$IBPATH/smpquery nodedesc $master_lid | sed -e 's/^Node Description:\.*\(.*\)/\1/'`

echo $f | grep -q "sFB-"
  if [ $? == 1 ] ; then
  # Master SM found on 4XXX or OFED server
      echo_red $f
  else
  # Master SM found on 2XXX or 9XXX
      g=`ibaddr $master_lid | awk '{print $2}' | awk -F: '{print $NF}'`
      echo_red "`saquery -S | grep -A 34 $g |awk '/ServiceData32.4/{a=substr($1,27);next} /ServiceData64.1/{b=substr($1,27);next} /ServiceData64.2/{c=substr($1,27); name=sprintf("%s%s%s", a,b,c); for(i=1;i<=length(name);i=i+2) {c="0x"substr(name,i,2); printf("%c",strtonum(c))} print "\n"}'`"
  fi

echo ""
