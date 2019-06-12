#!/bin/bash
##
# Copyright (C) Mellanox Ltd. 2001-2010.  ALL RIGHTS RESERVED.
#
# This software product is a proprietary product of Mellanox Ltd.
# (the "Company") and all right, title, and interest and to the software product,
# including all associated intellectual property rights, are and shall
# remain exclusively with the Company.
#
# This software product is governed by the End User License Agreement


for i in $( cat $1 ); do
	snmpwalk -c public -v2c $i sysName.0 | cut -d " " -f4 | tr -d '\n' 
	echo " " | tr -d '\n'
	snmpwalk -c public -v2c $i enterprises.5206.3.29.1.3.1007.1 | cut -d "\"" -f2
done
