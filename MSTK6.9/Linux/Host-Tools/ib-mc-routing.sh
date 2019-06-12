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



function print_switch_MC_ibroute_for_MLID()
{
	mgid=`saquery -g | grep -i -B1 $group | head -1 | awk -F\. '{print $NF}'`
                echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
                echo "                  " $group "       " $mgid
                echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
                echo "                        0                   1                   2                   3"
                echo "                 Ports: 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6"
                
				for guid in `ibswitches | awk '{print $(3)}'`; do
                        #lid=`ibaddr -L -G $guid  | awk '{print $NF}'`
                        ibroute -M -G $guid $group $group | grep -e ^0 | grep -v valid | sed s"/$group/$guid/gI"
						
						
                done

}

function print_MC_ibroute_for_all_switches()
{
	for guid in `ibswitches -t 100| awk '{print $(3)}' `; do
        	lid=`ibaddr -L -G $guid  | awk '{print $NF}'`
			swName=`saquery -O $lid` 
        	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
        	echo "          GUID:" $guid "  LID:" $lid "  Name:" $swName
        	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
        	echo "            0                   1                   2                   3"
        	echo "     Ports: 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6"

        	for mlid in `saquery -g | grep Mlid  | awk -F\. '{print $NF}' | uniq` ; do
                	# ibRoute=`ibroute -M -G $guid $mlid $mlid | grep -e ^0 | grep -v valid `
					ibroute -M -G $guid $mlid $mlid | grep -e ^0 | grep -v valid 
			done		
	done
}


function print_switches_ibroute_for_all_MLID()
{
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	echo "IBSWITCHES:"
	ibswitches
	echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
	for mlid in `saquery -g | grep Mlid  | awk -F\. '{print $NF}' | uniq`; do
		mgid=`saquery -g | grep -i -B1 $mlid | head -1 | awk -F\. '{print $NF}'` 
		echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo "			" $mlid "	" $mgid
		echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
		echo "                        0                   1                   2                   3"
		echo "                 Ports: 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6"
		for guid in `ibswitches | awk '{print $(3)}'`; do 
			#lid=`ibaddr -L -G $guid  | awk '{print $NF}'`
			ibroute -M -G $guid $mlid $mlid | grep -e ^0 | grep -v valid | sed s"/$mlid/$guid/gI" 
		done
	done
}


function usage() {
        echo Usage: `basename $0` "[ -s ] [ -g MLID ] [ -m ] [-v] [-h]"
        echo ""
        echo "options:"
        echo "          [-s]                            - Show MC groups spanning tree switches and ports"
        echo "          [-g MLID]                       - Show specific MC group spanning tree switches and ports"
        echo "          [-m]                            - Show ibroute -m for all switches"
        echo "          [-v]                            - Show version"
        echo "          [-h]                            - Show help"
        echo
        exit 1
}

# No option is given
[ $# -eq 0 ] && usage

while getopts mshvg: opt; do
        case $opt in
        s)
		print_switches_ibroute_for_all_MLID		
		exit
                ;;
        m)
		print_MC_ibroute_for_all_switches
		exit
                ;;
        g)
        	group=$OPTARG
		print_switch_MC_ibroute_for_MLID
		exit
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

exit
