#!/bin/bash


Day=$1
log_path=$2

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

smdb=${log_path}/opensm-smdb.dump
nodes_offset=`grep ^NODES $smdb | awk '{print $5}'`
nodes_start_line=`grep ^NODES $smdb | awk '{print $4}' | sed 's/\,//g'`
nodes_end_line=$((nodes_start_line + nodes_offset))

#echo $nodes_offset
#echo $nodes_start_line
#echo $nodes_end_line



egrep -i "ACTIVE to DOWN|ACTIVE to Init"  ${log_path}/opensm.log | egrep "$Day"   | awk '{print "date: "$1" "$2" "$3"  switch: "$15 " port: " $12}'  > flaps3.txt 
zcat  ${log_path}/opensm*.gz | egrep -i "ACTIVE to DOWN|ACTIVE to Init" | egrep "$Day" | awk '{print "date: "$1" "$2" "$3"  switch: "$15 " port: " $12}'  >> flaps3.txt

while read f1 f2 f3 f4 f5 guid f7 port 
do 
 guid1=`echo $guid| sed 's/\,//g'` 
 iblinkinfo -S $guid1 > /tmp/linkinfo.$guid1  
# side1=`smpquery nd -G $guid1| sed 's/Node Description//g' | cut -d "i" -f  2 | sed 's/sw/isw/g'` 
 side1=`grep -A $nodes_end_line START_NODES $smdb| grep $guid1 | awk '{print $7}' `
 side1_lid=`ibaddr -G $guid1 -L | awk '{print $NF}'`
 #side1_lid=`grep -A $nodes_end_line START_NODES $smdb| grep $guid | grep $port | awk '{print $7}' `
 
 
#side1=`sed -n ''`
# side1=`grep ` 

side2=`grep -A $port $guid1  /tmp/linkinfo.$guid1  | tail -n 1 | cut -d ']' -f 3 | sed 's/[()]//g' `
side2_port=`grep -A $port $guid1 /tmp/linkinfo.$guid1 | tail -n 1 | awk '{print $11}' | sed 's/\[//g'`
side2_lid=`grep -A $port $guid1 /tmp/linkinfo.$guid1 | tail -n 1 | awk '{print $10}'`
side2_uptime=`mlxuptime -d lid-$side2_lid | grep -i "up time"| awk '{print $5}'`

mlxlink -d lid-$side1_lid -p $port -mc > /tmp/mlxlink.$side1_lid
cable_pn=`grep -a 'Part Number' /tmp/mlxlink.$side1_lid | cut -d ":" -f 2`
cable_sn=`grep -a 'Serial Number' /tmp/mlxlink.$side1_lid | cut -d ":" -f 2`
raw_ber1=`grep -a 'Raw Physical BER' /tmp/mlxlink.$side1_lid | cut -d ":" -f 2`
eff_ber1=`grep -a 'Effective Physical BER' /tmp/mlxlink.$side1_lid | cut -d ":" -f 2`



echo -e "$f1 $f2 $f3 $f4 cable_pn :$cable_pn raw_ber:$raw_ber1 eff_ber:$eff_ber1 ${RED}$side1 lid:$side1_lid $guid1 $port ${NC} <-> ${YELLOW}$side2 lid:$side2_lid $side2_port ASIC uptime: $side2_uptime ${NC}"

done < flaps3.txt

