#!/bin/bash

echo ""
echo "SM DATA (sminfo)"
sminfo

with_cables="no"
mlxlink_flags="-ec"
skip_mlxlink="no"
mlxdump_sleep=10
mlxdump_flags="snapshot -m full"
ibdiagnet_path="/usr/bin/ibdiagnet"
ibdiagnet_flags="-pc --get_phy_info --extended_speeds all"
ibdiagnet_monitor_path="/tmp/mlnx/usr/ibdiagnet_monitor.py"
ibdiagnet_monitor_flags=" "
sysdump_command="/opt/tms/bin/cli -t enable 'debug generate dump'"
what_to_test="nothing"

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

echo -e "\nGenerating Sysdump"
#ssh -o "StrictHostKeyChecking=no" admin@127.0.0.1 cli \"enable\" \"debug generate dump\" \"show files debug-dump\" > /tmp/sysdump_name.txt
sysdump_name=`echo ${sysdump_command} | bash | grep "Generated dump sysdump" | awk '{print $3}'`
echo $sysdump_name
#sysdump_name=`grep "Generated dump sysdump" /tmp/sysdump_name | awk '{print $3}'`
if [[ $sysdump_name =~ "sysdump-" ]]; then
 echo -e "Detected sysdump $sysdump_name"
 echo -e "Copying /var/opt/tms/sysdumps/$sysdump_name to $log_dir/"
 cp /var/opt/tms/sysdumps/${sysdump_name} ${log_dir}/
 rm -f /var/opt/tms/sysdumps/${sysdump_name}
else
  echo -e "\nCouldn't determine generated Sysdump name, sysdump won't be collected"
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
  iblinkinfo &> ${log_dir}/iblinkinfo.txt
  # ibnetdiscover
  ibnetdiscover &> ${log_dir}/ibnetdiscover.txt
  # ibdiagnet
  mkdir $log_dir/ibdiagnet/
  $ibdiagnet_path ${ibdiagnet_flags} -o ${log_dir}/ibdiagnet &>> $log_dir/ibdiagnet/ibdiagnet_run.log
}

#####################################################################
function ibdiagnet_monitor_run {
 echo -e "\nRunning: $ibdiagnet_monitor_path  $ibdiagnet_monitor_flags "
 now_ibm=`date +%d-%M-%Y_%H-%M-%S`
 $ibdiagnet_monitor_path --out_csv=${log_dir}/ibdiagnet_monitor_out_${now_ibm}.csv ${ibdiagnet_monitor_flags} &> $log_dir/ibdiagnet_monitor_run.log
}

########################################################################

function mlxlink_lid {
# lid, $switch_name, num_ports
for port in {1..40}
do
  touch $log_dir/${2}/${2}_port_${port}.log
  echo "Switch $2 Port $port" >> $log_dir/${2}/${2}_port_${port}.log
  mlxlink_output=`mlxlink -d lid-$1 -p $port $mlxlink_flags 2>>$log_dir/${2}/${2}_port_${port}.log & `
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
    echo -en "Getting mlxlink data from ${mlxlink_switch_name} lid:${lid}\r"
    mlxlink_lid $lid $mlxlink_switch_name $mlxlink_num_ports
 done
}

function mlxdump_lid {
# lid , switch name
# mlxdumps
  for i in {1..3}
  do
    echo -en "$2 - mlxdump Instance: $i\r"
    echo "$2 - Instance: $i" >> ${log_dir}/${2}/mlxdump_log.log
    mlxdump -d lid-$1 ${mlxdump_flags} -o ${log_dir}/${2}/${2}_mlxdump_snapshot_${i}.udmp &>> ${log_dir}/${2}/mlxdump_log.log
  done
}

function mlxdump_all {
# instance number
 touch ${log_dir}/mlxdump_run.log
 for lid in `echo "$all_lids" `
 do
  #echo "instance # $1"
  instance=$1
  switch_name=`smpquery nd $lid | cut -d ";" -f 2 | sed 's/\//_/g' | sed 's/\:/-/'`
  #echo "main function: switch name $switch_name"
  if [[ ! -f ${log_dir}/$switch_name/mlxdump_log.log ]] ; then
        touch ${log_dir}/${switch_name}/mlxdump_log.log
  fi
  echo -e "Getting mlxdump $1 from lid: $lid  $switch_name " &>> ${log_dir}/mlxdump_run.log
  #echo -ne "Getting mlxdump $1 from lid: $lid  $switch_name \r"
  mlxdump_lid "$lid" "$switch_name"
done

}


# Main

# Get all switch lids

all_lids=`ibnetdiscover -p | egrep '^SW' | awk '{print $2}' | sort | uniq  `
echo -e "\nFound `echo "$all_lids"| wc -l` ASICS"

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

if [[ ! $what_to_test == "nothing" ]]; then
  echo -e "\n ##### Testing function $what_to_test ######"
  $what_to_test
else

  if [[ $skip_mlxlink == "no" ]]; then
     echo "Starting mlxlink phase"
     mlxlink_all
     echo -e "\033[2K"
     echo "Ending mlxlink phase"
  fi

  # mlxdumps
echo -e "\033[2K"
echo -e "Starting mlxdump phase"
  mlxdump_all
echo -e "\033[2K"
echo -e "Ending mlxdump phase"
  ib_commands
  sysdump
  cli_commands
  ibdiagnet_monitor_run

  # bundling all it a tgz file to Copy
  sleep 10
fi

tar czf /tmp/mr_health_log_${now}.tgz ${log_dir}/ &>/dev/null

if [[ ! -f /tmp/mr_health_log_${now}.tgz ]] ; then
   echo -e "\nERR: Couldn't create the file  /tmp/mr_health_log_${now}.tgz"
   echo -e "Try creating it on your own with:"
   echo -e "\n tar czf /tmp/mr_health_log_${now}.tgz ${log_dir}/"
else
 echo -e "\n\e[32mCreated log file /tmp/mr_health_log_${now}.tgz - COPY it to an external device \e[39m"

 echo "Deleting log $log_dir folder to save space"
if [[ -d  $log_dir ]]; then
  rm -rf ${log_dir}
fi

# cleaning core files
 rm -f /var/root/tmp/mlnx/core.* > /dev/null
fi
