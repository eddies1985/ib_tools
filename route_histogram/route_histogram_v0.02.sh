#!/bin/bash

once=true
switch_lid=0
Tpath="/tmp/switch_lft.txt"
Ntype=""
Switch_Name=""
all=false
declare -i Switch_ports_array




while getopts o:ah op
do
  case "$op" in
  #o) once=true;; 
  o) switch_lid="$OPTARG";;
  a) all=true;;
  h) echo "Usage -a -o [switch lid] " ;;# exit 1
  [?])  echo "test";; # exit 1;;
  
  esac
done

#if ["$once" eq true ]; then
#     
#fi

# init an array of ports , number of ports is passed as an argument
function init_port_array 
{
	for i in $(seq $1 $2)
	do
 	Switch_ports_array[$i]=0
 	#echo ${Switch_ports_array[${i}]}
	done;
}

#******************************************************************************************

#Querying NodeInfo and parsing the NoteType line
#

function check_node_type 
{
Ntype=`smpquery ni $1 | grep NodeType  | cut -d "." -f 25`
if [ "$Ntype" = "Channel Adapter" ];
  then
  echo "lid is A channel adapter"
  exit
fi

}
#******************************************************************************************

#Getting switch LFT to file
function get_switch_lfts
{
ibroute $1 > $Tpath
}

#******************************************************************************************

#Getting switch Name
function get_switch_name 
{ 
Switch_Name=`saquery -O  $1 `
#echo $Switch_Name
}
#******************************************************************************************
#Count Number of routes per port and save in Switch_ports_array
function count_routes
{ 
for i in  $(cat $Tpath | grep portguid | awk '{print $2}' ); do
      #echo $i;
      z="$(echo $i | sed 's/0*//')"
	Switch_ports_array[$z]+=1 
done
}
#******************************************************************************************
# Print Switch details - name
function print_switch_details
{
echo "Switch:  $1 " #LFT Histogram:"
}
#******************************************************************************************
# Print Port Numbers 
function print_port_numbers 
{
echo -n "Port #  : "
for i in $(seq $1 $2)
    do    
      printf "%4d" $i 
    
    if [ "$i" -eq "$2" ];
    then
      echo -e "\n"
    fi
    done;
}

#print Number of routes for each port

function print_number_routes
{
echo -n "# routes: "
for i in $(seq $1 $2)
do
 

printf "%4d"  ${Switch_ports_array[${i}]}


done;
echo -e "\n"
}



echo -e
 
init_port_array 0 36  
check_node_type $switch_lid

get_switch_name $switch_lid
get_switch_lfts $switch_lid
count_routes 
print_switch_details "$Switch_Name"

print_port_numbers 0 36
print_number_routes 0 36







