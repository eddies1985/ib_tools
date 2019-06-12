#!/bin/sh
# Copyright (C) Mellanox Ltd. 2001-2014.  ALL RIGHTS RESERVED.
#
# This software product is a proprietary product of Mellanox Ltd.
# (the "Company") and all right, title, and interest and to the software product,
# including all associated intellectual property rights, are and shall
# remain exclusively with the Company.
#
# This software product is governed by the End User License Agreement
#

VERSION=6.0
MyName=`basename $0`
HOST=$(hostname)
XDATE=$(date +%Y%m%d-%H%M)
IBPATH=${IBPATH:-/usr/sbin}

#Added --smkey flag for saquery -m commands as from MLNX_OFED 2.0- the default sm_key used is 0 ( untrusted)
sm_key="1"
ca_flags=" "

export LC_ALL=POSIX

echo ""
echo $MyName "Version" $VERSION
echo ""



function usage() {
        echo Usage: `basename $0` "[-v] [-h]"
        echo ""
        echo "options:"
        echo "          [-C ca name]                    - Ca name to use"
        echo "          [-P port #]                     - Ca port number to use"
        echo "          [-K sm_key #]                   - SM key value to use"
        echo "          [-h]                            - Show help"
        echo
        exit 1
}



# No option is given
#[ $# -eq 0 ] && usage

while getopts hv:C:P:K: opt; do
        case $opt in
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
	esac
done

saquery $ca_flags -g  | awk  -v key=$sm_key -v ca="$ca_flags" '  
/^MCMemberRecord/{
	printf("Multicast Group: \n")
	next
}
/MGID/{
	mgid=substr($1,25)
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
		printf("\t\tMulticastIP.............%u.%u.%u.%u\n", a4, a3, a2, a1)
	}
}


/Mlid/ {
	mlid=substr($1,25)
        printf("Members of %s MLID %s group:\n%s", pkey, mlid, msg);
	printf("Joined Members:\n");
        
	system("saquery --smkey " key   "  " ca " -m " mlid);
        printf("============================================================\n");
}
#/SL/ {
#	#print $0;
#	#system("saquery $ca_flags --smkey $key -m  $mlid")
#next
#}


{ print }'


echo ""
echo $MyName "Version" $VERSION
echo ""
