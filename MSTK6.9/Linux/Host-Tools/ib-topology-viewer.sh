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

VERSION=6.0
MyName=`basename $0`
HOST=$(hostname)
XDATE=$(date +%Y%m%d-%H%M)
IBPATH=${IBPATH:-/usr/sbin}
export LC_ALL=POSIX

echo ""
echo $MyName "Version" $VERSION
echo ""


swVerbose=false
caVerbose=false
internal=false
discover=true
timeout=2

netfile="/tmp/net"
swfile="/tmp/sw"
swguids="/tmp/swguids"
tempfile1="/tmp/t1"
tempfile2="/tmp/t2"

function usage() {
	echo Usage: `basename $0` "[ -t <topology-file>] [ -s ] [ -n ] [ -i ] [ -k <timeout in ms>]" 
	echo ""
	echo "options:"
	echo "     [-t topology-file ]  - The output of ibnetdiscover -p"
	echo "     [-s]             	  - Show Connected switch ports"
	echo "     [-n]             	  - Show Connected HCA ports"
	echo "     [-i]                 - Include internal ports"
	echo "     [-k MAD-timeout <default = $timeout>]                 - MAD timeout"
	echo "     [-h]                 - Show this help"
	echo
        exit 1
}

while getopts snihkt: opt; do
	case $opt in
        s)
                echo "Display connected switch ports "
		swVerbose=true
                ;;
        n)
                echo "Display connected HCA ports "
		caVerbose=true
                ;;
        i)
                echo "Display internal switch ports "
		internal=true
                ;;
	t)
                echo "Parsing ibnetdiscover ports file"
		topofile=$OPTARG
                discover=false
                ;;
	k)
		if [[ $OPTARG = *[[:digit:]]* ]]
		then
			timeout=$OPTARG
		fi
		;;
	h)
                usage
                ;;

	\?)
		usage
		;;
	esac
done

if [ ! -f $topofile ] ; then
	echo "$topofile doesnt exists!"
	usage
fi

if $internal; then
	if ! $discover; then
		cp $topofile $netfile 
	else
		eval ibnetdiscover -t $timeout -p > $netfile
	fi
else
	if ! $discover; then
	 	cat $topofile |egrep -v -i "sfb|/S" > $netfile
	else
		eval ibnetdiscover -t $timeout -p |egrep -v -i "sfb|/S" > $netfile
	fi
fi

GUIDS=`cat $netfile | grep -e ^SW | awk '{print $4}' | uniq`
#echo $GUIDS
#cat $netfile | grep -e ^SW | awk '{print $4}' | uniq > $swguids

if [ "$GUIDS" == "" ] ; then
	echo "No Switch Found"
	exit
fi

for guid in $GUIDS ; do  
	string="$guid..x"
	#desc=`cat $netfile| grep -e ^SW | grep $string  | grep \( | awk -F\' '{print $2}' | uniq`
	desc=`cat $netfile| grep -e ^SW | grep $string  | awk -F\' '{print $2}' | uniq`
	echo $desc==$guid >>$tempfile1
done

sort $tempfile1 -o $swfile

for guid in `awk -F== '{print $2}' $swfile`; do
	swDesc=`grep $guid $swfile | awk -F== '{print $1}'` 
	ca=`awk -vg=$guid '{if ($1 ~ "SW" && $4 ~ g && $8 ~ "CA") print $0}' $netfile >$tempfile1`
	caNumber=`cat $tempfile1 | wc -l`
	sw=`awk -vg=$guid '{if ($1 ~ "SW" && $4 ~ g && $8 ~ "SW") print $0}' $netfile >$tempfile2`
	swNumber=`cat $tempfile2 | wc -l`
	notConnected=`awk -vg=$guid '{if ($1 ~ "SW" && $4 ~ g && $7 != "-") print $0}' $netfile |wc -l`
	printf "%-82s\t" "$swDesc($guid)"
	#printf '\x1b\x5b1;31;40m%-2d\x1b\x5b1;37;40m' "$caNumber"
	printf '%d' "$caNumber"
	printf " HCA ports and "

	#printf '\x1b\x5b1;31;40m%-2d\x1b\x5b1;37;40m' "$swNumber"
	printf '%d' "$swNumber"
	printf " switch ports.\n"

	if  [ ${swNumber} > 0 ]; then
		if $swVerbose ; then
			cat $tempfile2
			echo ""
		fi
	fi
	if [ [${caNumber} > 0]  ]; then
		if $caVerbose ; then
			cat $tempfile1
			echo ""
		fi
	fi
	#echo_green "$notConnected Not connected"
done

rm -f $netfile
rm -f $swfile
rm -f $swguids
rm -f $tempfile1
rm -f $tempfile2
rm -f 0
rm -f 0]
printf "\e[0m"
