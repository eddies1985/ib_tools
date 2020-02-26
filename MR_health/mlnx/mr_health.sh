#!/bin/bash

echo ""
echo "SM DATA (sminfo)"
sminfo

with_cables="no"
mlxlink_flags="-ec"
skip_mlxlink="no"
mlxdump_sleep=60
mlxdump_flags="snapshot -m full"
ibdiagnet_path="/usr/bin/ibdiagnet"
ibdiagnet_flags="-pc --get_phy_info --extended_speeds all"
ibdiagnet_monitor_path="/tmp/mlnx/usr/ibdiagnet_path"
ibdiagnet_monitor_flags=" "
sysdump_command="/opt/tms/bin/cli -t enable 'debug generate dump'"
what_to_tet="nothing"

# parse command line arguments
for arg in "$@"
do
  case $arg in
      -cable|--with_cables)
      mlxlink_flags="-mec"
      shift
      ;;
      --skip_mlxlink)
      skip_mlxlink="yes"
      shift
      ;;
      --testing)
      shift
      what_to_test=$1
      ;;
  esac
done

############### function Sysdump ##################################

function sysdump {

echo -e "\nGenearing Sysdump"
#ssh -o "StrictHostKeyChecking=no" admin@127.0.0.1 cli \"enable\" \"debug generate dump\" \"show files debug-dump\" > /tmp/sysdump_name.txt
sysdump_name=` echo ${sysdump_command} | bash | grep "Generated dump sysdump" | awk '{print $3}'`
#sysdump_name=`grep "Generated dump sysdump" /tmp/sysdump_name | awk '{print $3}'`
if [[ $sysdump_name =~ "sysdump-" ]]; then
 echo -e "Detected sysdump $sysdump_name"
 echo -e "Copying /var/opt/tms/sysdumps/$sysdump_name to $log_dir/"
 cp /var/opt/tms/sysdumps/${sysdump_name} ${log_dir}/
 rm -f /var/opt/tms/sysdumps/${sysdump_name}
else
  echo -e "\nCouldn't determine generated Sysdump name"
fi
}

#####################################################################

function cli_commands {

#ssh -o "StrictHostKeyChecking=no" admin@127.0.0.1 cli \"enable\" \"show power \" > ${log_dir}/show_power_consumers.txt
/opt/tms/bin/cli -t enable "show power consumers" > ${log_dir}/show_power_consumers.txt

}

#####################################################################

function ib_commands {

  # iblinkinfo
  iblinkinfo > ${log_dir}/iblinkinfo.txt
  # ibnetdiscover
  ibnetdiscover > ${log_dir}/ibnetdiscover.txt
  # ibdiagnet
  $ibdiagnet_path ${ibdiagnet_flags} -o ${log_dir}/ibdiagnet
}

#####################################################################
function ibdiagnet_monitor {
 echo -e "\nRunning: $ibdiagnet  $ibdiagnet_flags "
 $ibdiagnet_monitor $ibdiagnet_flags
}

########################################################################

function mlxlink_lid {
# lid, $switch_name, num_ports
for port in {1..40}
do
  touch $log_dir/${2}/${2}_port_${port}.log
  echo "Switch $2 Port $port" >> $log_dir/${2}/${2}_port_${port}.log
  mlxlink_output=`mlxlink -d lid-$1 -p $port/2 $mlxlink_flags 2>>$log_dir/${2}/${2}_port_${port}.log & `
  echo "$mlxlink_output" | sed -r "s/[[:cntrl:]]\[[0-9]{1,3}m//g" >> $log_dir/${2}/${2}_port_${port}.log

# In case we have split on external ports - check if switch num ports = 81 A.K.A split_mode=1
if [[ $3 -eq 81 ]]
then
  if [[ $port -lt 21  ]]
  then
     touch $log_dir/${switch_name}/${switch_name}_port_${port}_split_2.log
     echo -e "\nSwitch $switch_name Port $port/2" >> $log_dir/${switch_name}/${switch_name}_port_${port}_split_2.log
     mlxlink_output=`mlxlink -d lid-$1 -p $port/2 $mlxlink_flags 2>>$log_dir/${2}/${2}_port_${port}_split_2.log & `
     echo "$mlxlink_output" | sed -r "s/[[:cntrl:]]\[[0-9]{1,3}m//g" >> $log_dir/${2}/${2}_port_${port}_split_2.log
  fi
fi
done
}

##########################################################################

function mlxlink_all {
  for lid in `echo "$all_lids" `
  do
    mlxlink_switch_name=`smpquery nd $lid | cut -d ";" -f 2 | sed 's/\//_/g' | sed 's/\:/-/'`
    mlxlink_num_ports=`smpquery ni $lid | grep NumPorts | tr -d '.' | cut -d ":" -f 2`
    echo -e "\nGetting mlxlink data from $mlxlink_switch_name"
    mlxlink_lid $lid $mlxlink_switch_name $mlxlink_num_ports
 done
}

function mlxdump_lid {
# instance number , lid , switch name

 #echo "sub function mlxdump -d lid-$2 snapshot -m full -o ${log_dir}/${3}/${3}_mlxdump_snapshot_${1}.udmp "
  #echo "lid: $2"
  #echo "instance # $1"
  #echo "Switch Name: $3"

 #mlxdump -d lid-$2 snapshot -m full -o ${log_dir}/${3}/${3}_mlxdump_snapshot_${1}.udmp >> ${log_dir}/${3}/mlxdump_log_$1.log
  echo "Instance: $1" >> ${log_dir}/${3}/mlxdump_log.log
  mlxdump -d lid-$2 ${mlxdump_flags} -o ${log_dir}/${3}/${3}_mlxdump_snapshot_${1}.udmp &>> ${log_dir}/${3}/mlxdump_log.log
}

function mlxdump_all {
# instance number
 for lid in `echo "$all_lids" `
 do
  #echo "instance # $1"
  instance=$1
  switch_name=`smpquery nd $lid | cut -d ";" -f 2 | sed 's/\//_/g' | sed 's/\:/-/'`
  #echo "main function: switch name $switch_name"
  if [[ ! -d ${log_dir}/$switch_name/mlxdump_log.log ]] ; then
        touch ${log_dir}/$switch_name/mlxdump_log.log
  fi
  echo -e "\nGetting mlxdump $1 from $switch_name lid: $lid"
  mlxdump_lid $instance "$lid" "$switch_name"
done

}


# Main

# Get all switch lids

all_lids=`ibnetdiscover -p | egrep '^SW' | awk '{print $2}' | sort | uniq  `

now=`date +%d_%m_%Y_%H_%M`
log_dir="/var/log/mr_health_logs_${now}"
echo -e "\nCreating log dir $log_dir"
if [[ -d $log_dir ]]; then
  echo -e "\n$log_dir already exists"
else
  mkdir ${log_dir}
fi

for lid in `echo "$all_lids" `
do
  switch_name=`smpquery nd $lid | cut -d ";" -f 2 | sed 's/\//_/g' | sed 's/\:/-/'`
  #num_ports=`smpquery ni $lid | grep NumPorts | tr -d '.' | cut -d ":" -f 2`
  #echo ""
  # create a directory for each switch device
  if [[ ! -d $log_dir/${switch_name} ]]; then
    mkdir $log_dir/${switch_name}
  fi
done

if [[ ! what_to_test == "nothing" ]]; then
  echo -e "\n ##### Testing function $what_to_test ######"
  $what_to_test
else

  if [[ $skip_mlxlink == "no" ]]; then
     mlxlink_all
  fi

  # mlxdumps

  mlxdump_all 1 &
  sleep $mlxdump_sleep
  mlxdump_all 2 &
  sleep $mlxdump_sleep
  mlxdump_all 3 &
  sleep $mlxdump_sleep

  ib_commands
  sysdump
  cli_commands

  # bundling all it a tgz file to Copy
  sleep 10
fi

tar czf /tmp/mr_health_log_${now}.tgz ${log_dir}/

if [[ ! -f /tmp/mr_health_log_${now}.tgz ]] ; then
   echo -e "\nERR: Couldn't create the file  /tmp/mr_health_log_${now}.tgz"
   echo -e "Try creating it on your own with:"
   echo -e "\n tar czf /tmp/mr_health_log_${now}.tgz ${log_dir}/"
else
 echo ""
 echo "Created log file /tmp/mr_health_log_${now}.tgz - COPY it to an external device"
 echo ""

 echo "Deleting log $log_dir folder to save space"
if [[ -d  $log_dir ]]; then
  rm -rf ${log_dir}
fi

# cleaning core files
 rm -f /var/root/tmp/mlnx/core.* > /dev/null
fi
