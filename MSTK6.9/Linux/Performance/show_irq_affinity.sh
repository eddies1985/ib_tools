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

if [ -z $1 ]; then 
	IRQS=$(cat /proc/interrupts | grep eth-mlx | awk '{print $1}' | sed 's/://')
else
	IRQS=$(cat /proc/interrupts | grep $1 | awk '{print $1}' | sed 's/://')
fi

for irq in $IRQS
do
	echo -n "$irq: "
	cat /proc/irq/$irq/smp_affinity
done

