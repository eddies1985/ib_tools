#!/bin/bash


port=$2
lid=$1
sampleTime=$3

#while [ 1 ]; 
#do 
	RcvData1=`perfquery -x $lid $port | grep RcvData  | sed 's/PortRcvData\:.....................//g'` ; 
	XmitData1=`perfquery -x $lid $port | grep XmitData | sed 's/PortXmitData\:....................//g'` ;	
	
	sleep $sampleTime

	RcvData2=`perfquery -x $lid $port | grep RcvData  | sed 's/PortRcvData\:.....................//g'` ;
        XmitData2=`perfquery -x $lid $port | grep XmitData | sed 's/PortXmitData\:....................//g'` ;


	# calculate to Megabytes
	RcvRate=`echo "scale=5 ;(($RcvData2 - $RcvData1)*4)/$sampleTime" | bc `
	XmitRate=`echo "scale=5 ;(($XmitData2 - $XmitData1)*4)/$sampleTime" | bc `
	
	RcvRate1=`echo  "$RcvRate/1048576" | bc `
	XmitRate1=`echo "$XmitRate/1048576"| bc `

	echo "RcvRate = $RcvRate1 [MBps]  XmitRate = $XmitRate1 [MBps] "  	
#done

