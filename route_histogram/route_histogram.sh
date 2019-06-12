#!/bin/bash

switch_lid=$1


Tpath="/tmp/switch_lft.txt"
Ntype=""
Switch_Name=""
declare -i Switch_ports_array

#Initializing switch port array to 0
for i in $(seq 0 36)
do
 Switch_ports_array[$i]=0
 #echo ${Switch_ports_array[${i}]}
done;


#check if lid is realy switch

#Querying NodeInfp and parsing the NoteType line
Ntype=`smpquery ni $switch_lid | grep NodeType  | cut -d "." -f 25`
if [ "$Ntype" = "Channel Adapter" ];
  then
  echo "lid is A channel adapter" 
  exit
fi

#echo "good"

#Getting switch LFT to file
ibroute $switch_lid > $Tpath

#Getting switch Name

Switch_Name=`smpquery ND $switch_lid | cut -d "." -f 6 `

for i in  $(cat $Tpath | grep portguid | awk '{print $2}' ); do
      #echo $i;
      z="$(echo $i | sed 's/0*//')"
	Switch_ports_array[$z]+=1 
done

echo "Switch: " $Switch_Name "  LFT Histogram:"
echo -n "Port #  : "

# Print Port Numbers 
for i in $(seq 0 36)
    do    
      echo -n $i "   " 
    
    if [ "$i" -eq "36" ];
    then
      echo -e "\n"
    fi
    done;


#print Number of routes for each port

echo -n "# routes: "
for i in $(seq 0 36)
do
 

if [ "$i" -gt "9" ]; then

	echo -n "     "

else
        if [ "$i" -ne "0" ]; then 
	echo -n "    "
        fi
fi
echo -n  ${Switch_ports_array[${i}]}


done;
echo -e "\n"

