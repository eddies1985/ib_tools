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
# Please send your feedback/comments to YAIRG@MELLANOX.COM
#
#

VERSION=6.0
MyName=`basename $0`
HOST=$(hostname)
XDATE=$(date +%Y%m%d-%H%M)
export LC_ALL=POSIX


nodes=/tmp/MCnodes.$$
groups=/tmp/MCgroups.$$
nodeLookup=false
groupLookup=false
MAX_GROUPS=128
ca_flags=""

#Added --smkey flag for saquery -m commands as from MLNX_OFED 2.0- the default sm_key used is 0 ( untrusted)
sm_key="1"


echo ""
echo $MyName "Version" $VERSION
echo ""

function mgid2ip()
{
	local ip=`echo $1 | awk '
        #echo local_ip
	{
		mgid=$1
		n=split(mgid, a, ":")
			if (a[2] == "401b") {
			upper=strtonum("0x" a[n-1])
			lower=strtonum("0x" a[n])
			addr=lshift(upper,16)+lower
			addr=or(addr,0xe0000000)
			a1=and(addr,0xff)
			addr=rshift(addr,8)
			a2=and(addr,0xff)
			addr=rshift(addr,8)
			a3=and(addr,0xff)
			addr=rshift(addr,8)
			a4=and(addr,0xff)
			printf("%u.%u.%u.%u", a4, a3, a2, a1) 
		}
		if (a[2]== "601b")
                {
			printf ("IPv6")
		}
                if (a[2]== "e01b")
                {
			printf ("EoIB")
                       
		}
                 if (a[2]== "a01b")
                {
			printf ("FCA")
                       
		}
	}'`
	echo -en $ip
}

echo_red ()
{
echo -en "\\033[1;031m"$1"\\033[0;39m"
return 0
}

function usage() {
        echo Usage: `basename $0` "[ -n NODENAME | sum ] [ -g MLID | sum ] [-v] [-h]"
        echo ""
        echo "options:"
        echo "		[-n NODENAME | sum]             - Show MC groups for node, use sum for nodes summary "
        echo "		[-g MLID | sum]                 - Show MC group members, use sum for summary all MC groups "
        echo "		[-v]				- Show version"
	echo "		[-C ca name]            	- Ca name to use"
	echo "		[-P port #]      		- Ca port number to use"
	echo "		[-K sm_key #]                   - SM key value to use"
	echo "		[-h]				- Show help"
	echo 
        exit 1
}

# No option is given
[ $# -eq 0 ] && usage

while getopts n:hvg:C:P:K: opt; do
	case $opt in
	n)
		node=$OPTARG
		nodeLookup=true
		;;
	g)
		group=$OPTARG
		groupLookup=true
		;;
	
	C)
		ca_flags+="-C $OPTARG "
		;;

	P)
		ca_flags+="-P $OPTARG "
		;;

	K)	
		sm_key="$OPTARG"
		;;

	v)
		echo "$MyName Version $VERSION"
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


saquery --smkey $sm_key $ca_flags -m | while read line; do
	k=${line%%.*}
	v=${line##*.}
	if [ "$k" == "Mlid" ]; then
		mlid=$v
	elif [ "$k" == "MGID" ]; then
		ip=`mgid2ip $v`
                #type=``
	elif [ "$k" == "NodeDescription" ]; then
		echo "$mlid $ip $v " >> $groups

		# Ignore switches and routes
		if [[ "$v" =~ "sLB|sFB|ISR[29]|[42]036|IB-to-TCP|sRB-20210G|MF0;" ]]; then
			continue
		fi

		echo "$v " >> $nodes
	fi
done

if $nodeLookup ; then
	if [ $node == "sum" ] ; then
		# Summary how many gruops for each node
		echo "Node Name	MC Groups #"
		sort $nodes | uniq -c | while read line; do
			gcount=`echo $line | cut -d " " -f 1`
			name=`echo $line | cut -d " " -f 2-`
			echo -en "$name	--->  $gcount"
			if [ $gcount -gt $MAX_GROUPS ]; then
				echo_red "	-- PERFORMANCE DROP WARNING --"
			fi
			echo
		done
	else
		# how many gruops for $node
		echo -n "$node is a member in the following MC groups(" 
		echo_red `grep "$node " $groups | wc -l`
		echo "):"
		grep -i "$node " $groups | awk '{printf("%s %s\n", $1, ($2=="IPv6"?"":$2))}'
	fi
fi

if $groupLookup ; then	
	if [ $group == "sum" ] ; then
		#summary how many members for each MC group
		awk '{print $1, $2}' $groups | sort -k1 -n | uniq -c | awk '{printf("%s %s (%s)\n", $2, $3, $1)}'
                #echo $groups
                #mgid2ip $v
                
        else
		#  how many members in $group
		grep -i $group $groups > /tmp/g.$group

		members=`wc -l /tmp/g.$group`
		ip=`awk '{print $2; exit}' /tmp/g.$group` 
		echo -en "MC group $group (${ip}) have " 
		echo_red $members 
		echo " members:"
		cat /tmp/g.$group | cut -d " " -f 3-
		rm -f /tmp/g.$group
	fi
fi

rm -f $nodes $groups

