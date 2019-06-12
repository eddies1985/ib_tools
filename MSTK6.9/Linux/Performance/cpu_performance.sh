#!/bin/bash
# Copyright (C) Mellanox Ltd. 2001-2010.  ALL RIGHTS RESERVED.
#
# This software product is a proprietary product of Mellanox Ltd.
# (the "Company") and all right, title, and interest and to the software product,
# including all associated intellectual property rights, are and shall
# remain exclusively with the Company.
#
# This software product is governed by the End User License Agreement
#
echo "Checking your cpu frequency settings..."
MODE=$1
NUM_CPU="1"
rm -rf /tmp/cpuinfo
cat /proc/cpuinfo  | grep processor > /tmp/cpuinfo
NUM_CPU=$(less /proc/cpuinfo | grep -c processor)
COUNTER=0
if [ -e /sys/devices/system/cpu/cpu0/cpufreq ]; then
	if [[ "$MODE" == "" || "$MODE" == "performance" ]] ; then
		echo "changing cpu frequency to performance mode"
		while [ $COUNTER -lt $NUM_CPU ]; do
			echo performance > /sys/devices/system/cpu/cpu$COUNTER/cpufreq/scaling_governor
			let COUNTER=$COUNTER+1
		done
	elif [ "$MODE" == "ondemand" ]; then
		echo "changing cpu frequency to ondemand mode"
		while [ $COUNTER -lt $NUM_CPU ]; do
			echo ondemand > /sys/devices/system/cpu/cpu$COUNTER/cpufreq/scaling_governor
			let COUNTER=$COUNTER+1
		done
	fi
else
	echo "cpu frequency change is not supported"
fi
echo "done."

