#! /bin/bash
# Copyright (C) Mellanox Ltd. 2001-2010.  ALL RIGHTS RESERVED.
#
# This software product is a proprietary product of Mellanox Ltd.
# (the "Company") and all right, title, and interest and to the software product,
# including all associated intellectual property rights, are and shall
# remain exclusively with the Company.
#
# This software product is governed by the End User License Agreement
#

if [ -z $2 ]; then
	echo "usage: $0 <interface name> <node id>"
	exit 1
fi
interface=$1
node=$2

IRQS=$(cat /proc/interrupts | grep $interface | awk '{print $1}' | sed 's/://')

cpulist=$(cat /sys/devices/system/node/node$node/cpulist ) 
if [ "$(echo $?)" != "0" ]; then 
	echo "Node id '$node' does not exists."
	exit 
fi
CORES=$( echo $cpulist | sed 's/,/ /g' | wc -w )
for word in $(seq 1 $CORES)
do
	SEQ=$(echo $cpulist | cut -d "," -f $word | sed 's/-/ /')	
	if [ "$(echo $SEQ | wc -w)" != "1" ]; then
		CPULIST="$CPULIST $( echo $(seq $SEQ) | sed 's/ /,/g' )"
	fi
done
if [ "$CPULIST" != "" ]; then
	cpulist=$(echo $CPULIST | sed 's/ /,/g')
fi
CORES=$( echo $cpulist | sed 's/,/ /g' | wc -w )
echo Discovered irqs: $IRQS
I=1  
for IRQ in $IRQS 
do 
	core_id=$(echo $cpulist | cut -d "," -f $I)
	echo $(printf "%x" $((2**core_id)) ) > /proc/irq/$IRQ/smp_affinity 
	I=$(( (I%CORES) + 1 ))
done
echo irqs were set OK.


