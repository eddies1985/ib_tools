#!/bin/bash

once=true
switch_lid=0
Tpath="/tmp/switch_lft.txt"
Ntype=""
Switch_Name=""
all=false
Got_Lid=false
OnlyHosts=false
switches=""
declare -r OPTSTRING="o:ahH"
declare -i Switch_ports_array
declare -a Switch_ports_percentage
declare -i Total_routes
declare -i port_percentage
declare  port

declare op


# init an array of ports , number of ports is passed as an argument
function init_port_array 
{

	for z in $(seq $1 $2)
	do
 	Switch_ports_array[$z]=0
 	#echo ${Switch_ports_array[${z}]}
	done;
}

#******************************************************************************************

#Querying NodeInfo and parsing the NoteType line
#

function check_node_type 
{
Ntype=`smpquery ni $1 | grep NodeType  | cut -d "." -f 25`
#echo $Ntype
if [ "$Ntype" == "Channel Adapter" ]
  then
  #echo "lid is A channel adapter"
  return 0
else 
  return $1
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
Total_routes=0
for i in  $(cat $Tpath | grep portguid | awk '{print $2}' )
 do
      #echo $i;
      z="$(echo $i | sed 's/0*//')"
	Switch_ports_array[$z]+=1 
	Total_routes+=1
done
}


function count_host_routes
{
 Total_routes=0
 echo "Only Hosts"
for i in  $(cat $Tpath | grep portguid |  grep "(Channel Adapter" |  awk '{print $2}' )
 do
      #echo $i;
      z="$(echo $i | sed 's/0*//')"
	Switch_ports_array[$z]+=1 
	Total_routes+=1
done
}
#******************************************************************************************

function calculate_precentage
{
 #declare -i port
 for i in $(seq $1 $2)
  do
   port=${Switch_ports_array[ ${i} ] }
   port_percentage=`echo $port*100/$Total_routes | bc`
   #port_remainder=  [ Switch_port_array[$i] / Total_routes % 100 ]
   
   Switch_ports_percentage[$i]=$port_percentage

  done
}

#******************************************************************************************
# Print Switch details - name

function print_switch_details
{
echo "Switch:  $1 " 
#LFT Histogram:"
}

#******************************************************************************************
#Print Port Numbers 

function print_port_numbers 
{
printf "Port      :"
for i in $(seq $1 $2)
    do    
      printf "%5d|" $i 
    
    if [ "$i" -eq "$2" ];
    then
      echo -e "\n"
    fi
    done;
}

function print_all_switch_data
{
 echo "port		:"
 for i in $(seq $1 $2)
 do 
   echo "sth"
 done
}

#*******************************************************************************************
#print Number of routes for each port

function print_number_routes
{
printf "Routes    :"
for i in $(seq $1 $2)
do
 

printf "%5d|"  ${Switch_ports_array[${i}]}


done;
echo -e "\n"
}

#*******************************************************************************************
function print_precentage
{
printf "Percentage:"
 
 for i in $(seq $1 $2)
  do
   printf "%4d%s|"  ${Switch_ports_percentage[${i}]} "%"
  done
}


#*******************************************************************************************


function Help
{
echo "Usage -a | -o [switch lid in  a decimal format] | -H" 

}


#******************************************************************************************
#*****************Main Program*************************************************************
#******************************************************************************************

# empty line
echo -e

OPTERR=0
declare -i OPTARG

while getopts "$OPTSTRING" op
do 
 case "$op" in 
  o) 
     if [ "$OPTARG" -eq "$OPTARG" ]
     then
        if [ $OPTARG == 0 ]
        then
          echo "LID = 0 , Exiting"
          exit
        else
     	#echo "lid is number"
     	switch_lid="$OPTARG"
        Got_Lid=true
        fi 
     else
        Help
     	echo "-o option expects a Deximal LID value $OPTARG is not Decimal :) "
     	exit  
     fi
     

     #echo "-o was triggered : Route Histogram for a single Switch LID= $switch_lid" >&2   
     ;;
  a) 
     all=true
     #echo "-a was triggered : Route Histogram for all Fabric switches" >&2
     ;;
  H)
     OnlyHosts=true
	 echo "Counting only Host routes"
	 ;;
  h) Help  
     exit 1
     ;;
  \?])  echo "Invalid option: -OPTARG" >&2
      Help
      exit 
      ;;
  
  esac
 
done
#echo $op
#echo $OPTERR
#echo $OPTIND
#echo $OPTARG

#if ["$once" eq true ]; then
     
#fi


# checking if there are any arguments, if zero exit


if  [ $# -eq 0 ]
  then
  echo "expecting arguments"
  Help
  #echo "Usage : route_histogram [-a | -o switch LID] "
  exit
fi  

if [ $Got_Lid == false ] && [ $all == false ]
then
	echo -e "-o was invoked but no Lid Argument \n"
 	Help
 	exit
fi

 
# checking to see if provided LID is a switch . if not - Exit
if [ $all == false ]
then
	check_node_type $switch_lid
	if [ $? == 0 ]
  	then
        Help
  	echo "LID $switch_lid is not a Switch! , Exiting "
  	exit
	fi 
fi 


if [ $all == false ] 
then   
   switches=$switch_lid
else
   switches=`ibswitches | cut -d '"' -f 3 | awk '{print $5}' `
fi

for i in $switches
do
        init_port_array 0 36
	get_switch_name $i
	get_switch_lfts $i
	if [ $OnlyHosts == false ]
	then 
		count_routes 
	else
		count_host_routes
	fi
	calculate_precentage 0 36
	print_switch_details "$Switch_Name"
	print_port_numbers 0 36
	print_number_routes 0 36
 	print_precentage 0 36
	echo -e "\n"
done
