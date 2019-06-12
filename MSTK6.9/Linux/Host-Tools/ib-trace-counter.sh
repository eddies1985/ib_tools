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


source=""
dest=""
dataType=""
RealdataType=""
mlid=""
dname=false
max_len=0
byLID=false
MC=false
IBTRACERT_OPTIONS=""


echo ""
echo $MyName "Version" $VERSION
echo ""


#Function to print with color
echo_red ()
{
echo -e "\\033[1;031m"$1"\\033[0;39m"
return 0
}

 

#The Usage function
function usage() {
	dataTypeArray=`perfquery  | egrep -v 'Select|#' | cut -d ":" -f 1 | awk '{print"\t\t\t" $1}'`
	echo
   	echo "Usage:" `basename $0` "<-s Source> <-d Dest> <-c Counter> [-m MLID] [-l] [-n] [-v] [-h]"
        echo ""
        echo "Options:"
	echo "	[-s Source]  - The specified source lid/nodename  nodename by default"
        echo "	[-d Dest]    - The specified destination lid/nodename  nodename by default"
        echo "	[-c Counter] - Specify the counter type:"
		for counter in "${dataTypeArray[@]}"  
		do
			printf  "$counter "
        done
		echo ""
		echo "	[-m MLID]    - Multicast trace of the mlid"
        echo "	[-l]   	     - Use LID as source and destination"
        echo "	[-n]   	     - Show Node Descriptions"
	echo
	echo "	[-v]         - Show version"
        echo "	[-h]         - Show help"
        echo

        exit -1
}


while getopts m:s:d:hlnvc: opt; do
        case $opt in
        s)
                source=$OPTARG
                ;;
        d)
                dest=$OPTARG
                ;;
        c)
                dataType=$OPTARG
                ;;
        l)
                byLID=true
                ;;
        m)
                mlid=$OPTARG
				IBTRACERT_OPTIONS="-m $mlid -t 100"
				MC=true
                ;;
		n)	
			dname=true
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

if [[ -z "$source" || -z "$dest" || -z "$dataType" ]] ;  then
	usage
fi 

# get real counter name from perfquery output

RealdataType=`perfquery  | grep -i xmitc | cut -d ":" -f 1`

echo ""
echo "Printing the $RealdataType counter for each port in path between $source and $dest."
echo "------------------------------------------------------------------------------"

if ( $byLID ) ; then
	lid1=$source
	lid2=$dest

	#Tell user which LID is not reachable.
	status=`ibaddr -t 100 $lid1 | awk '{print $3'}`
	if [[ !  "$status" == "LID" ]]; then
       	    echo "$source could not be reached"
            echo
       	    exit 2
	fi
	status=""
	status=`ibaddr -t 100 $lid2 | awk '{print $3'}`
	if [[ ! $status == "LID" ]]; then
      	   echo "$dest could not be reached"
	   echo
       	  exit 2
	fi

else
	lid1=`ibnetdiscover -t 100| grep -i $source | grep -i lid | awk {'print $7'}`
	lid2=`ibnetdiscover -t 100| grep -i $dest | grep -i lid | awk {'print $7'}`
fi
if [[ -z "$lid1" ]]; then
        echo_red "$source can't be reached"
	exit
elif [[ -z "$lid2" ]]; then
        echo_red "$dest can't be reached"
	exit
fi


if ( $MC ) ; then
	
	ibtracert $IBTRACERT_OPTIONS $lid1 $lid2 | awk -F: '{print $NF}' | grep -q "can't"
	if [ $? == 0 ] ; then
		echo "can't find a multicast route from $source to $dest on $mlid"
		exit
	fi
	#echo "ibtracert $IBTRACERT_OPTIONS $lid1 $lid2"
	lidArray=(`ibtracert $IBTRACERT_OPTIONS $lid1 $lid2  | awk '/^From/{print $7;next}; /^\[/ {print $6; next} '| awk -F- '{print $1}'`)
	portArray=(`ibtracert $IBTRACERT_OPTIONS $lid1 $lid2 | grep -e "^\[" | sed 's/\[/ /g' | awk '{print $1 $5; next}' | sed 's/\]/ /g' `)
else
	#echo "ibtracert $IBTRACERT_OPTIONS $lid1 $lid2"
	lidArray=(`ibtracert $IBTRACERT_OPTIONS $lid1 $lid2  | awk '/^From/{print $7;next}; /^\[/ {print $7; next} '| awk -F- '{print $1}'`)
	portArray=(`ibtracert $IBTRACERT_OPTIONS $lid1 $lid2 | sed s'/\}/ /g' | awk ' /^\[/ {print $1 $6; next}'  | sed s'/\[/ /g' | sed s'/\]/ /g' `)
fi

numOfPort=${#portArray[@]}
numOfLid=${#lidArray[@]}

if ( $dname ); then
	for element in $(seq 0 $(( numOfLid - 1 ))); do    
			deviceArray[$element]=`smpquery nodedesc ${lidArray[$element]} | awk -F\. '{print $NF}' | sed 's/  / /g'`
			len=${#deviceArray[$element]}
			if [ $len -gt $max_len ] ; then
				max_len=$len
			fi
	done
	let max_len=$max_len+2
fi
firstLid=${lidArray[0]}
printf "LID %-4s" "$firstLid"
printf "Port %-2s " "${portArray[0]}"
if ( $dname  ); then
	printf " %-*s" $max_len "${deviceArray[0]}"
fi
toBePrinted=`perfquery $firstLid ${portArray[0]} 2>/dev/null| grep -i $dataType`

if [ -z "$toBePrinted" ]; then
	echo_red "No Data Available"
else
	echo_red $toBePrinted
fi

let guidToPrint=$numOfGuids-1
let lidToPrint=$numOfLid-1
let portToPrint=$numOfPort-1


guidCounter=1
lidCounter=1
portsCounter=1
deviceCounter=1

while [ $lidCounter -lt $lidToPrint ] ; do
	printf "LID %-4s" "${lidArray[$lidCounter]}"
        printf "Port %-2s " "${portArray[$portsCounter]}"
	if ( $dname ); then	
		printf " %-*s" $max_len "${deviceArray[$deviceCounter]}"
	fi
	toBePrinted=`perfquery  ${lidArray[$lidCounter]} ${portArray[$portsCounter]} 2>/dev/null| grep -i $dataType`
	if [ -z "$toBePrinted" ]; then
	  echo_red "No Data Available"
	else
      	  echo_red $toBePrinted
	fi
	
	let portsCounter=$portsCounter+1	

	printf "LID %-4s" "${lidArray[$lidCounter]}"
        printf "Port %-2s " "${portArray[$portsCounter]}"
	if ( $dname ); then	
		printf " %-*s" $max_len "${deviceArray[$deviceCounter]}"
	fi
        toBePrinted=`perfquery ${lidArray[$lidCounter]} ${portArray[$portsCounter]} 2>/dev/null| grep -i $dataType`

        if [ -z "$toBePrinted" ]; then
          echo_red "No Data Available"
        else
          echo_red $toBePrinted
        fi

	
	let portsCounter=$portsCounter+1	
	let guidCounter=$guidCounter+1	
	let lidCounter=$lidCounter+1	
	let deviceCounter=$deviceCounter+1
done

lastGuid=${guidArray[$guidCounter]}
lastPort=${portArray[$portsCounter]}
lastLid=${lidArray[$lidCounter]}
lastDevice=${deviceArray[$deviceCounter]}

printf "LID %-4s" "$lastLid"
printf "Port %-2s " "$lastPort"
if ( $dname ); then
	printf " %-*s" $max_len "$lastDevice"
fi

toBePrinted=`perfquery $lastLid $lastPort 2>/dev/null| grep -i $dataType` 
if [ -z "$toBePrinted" ]; then
	echo_red "No Data Available"
else
	echo_red $toBePrinted
fi

echo "------------------------------------------------------------------------------"
echo ""
exit 1
