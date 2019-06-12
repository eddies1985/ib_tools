##############################################################
#Mellanox Support Tool Kit - MSTK                            #
#For any assitance please contact - support@mellanox.com     #
##############################################################



########
#Linux #
########
#############
#Performance#
#############

#---------------#
#Supported TOOLS#
#---------------#

1) mlnx_tune - Mellanox performance tool, run with -rc, to dump system status, with colors and without setting a profile

#-----------------#
#Unsupported TOOLS#
#-----------------#

2) mlnxperftuner - Mellanox performance tool, run with --view, to show performance tunning suggestions, and with --allow_changes to tweak the OS
3) cpu_performance.sh - Set CPU frequency to maximum
4) set_irq_affinity.sh - Distribute evenly across cores
5) show_irq_affinity.sh - Show current affinity
6) set_irq_affinity_bynode.sh - Assign to a NUMA node

##############
#SXxxxx TOOLS#
##############

1) CommandsForSX.pl - Run predefined commands on multi MLNX_OS switches, and write output into a text file
2) Unmanaged_Switches_Set_NodeDescription_v3.5.py - Change the node description of unmanaged Mellanox Infiniscale4 and SwitchX switches.

############
#Host TOOLS#
############

Download these tools to one of your OFED nodes and run:


1) ib-find-bad-ports.sh - Scan all fabric port for reduced width and speed ports, run from any server which runs OFED. 
2) ib-find-disabled-ports.sh - Scan all fabric port for disabled ports, run from any server which runs OFED, or from the 4036/2036 switches.
3) ib-find-sm.sh - Scan all fabric for active subnet managers, run from any server which runs OFED, or from the 4036/2036 switches. 
4) ib-mc-info.sh - Show Multicast (MC) group join information for IB nodes (who is joined to what group) and IB MC groups (what nodes are join to a specific group) , run from any server which runs Mellanox OFED
5) ib-mc-routing.sh - Show MC groups spanning tree switches and ports, use this tool to provide Mellanox engineering the required MC routing debug information,  run from any server which runs Mellanox OFED
6) ib-mgid-to-ip.sh - Show Multicast Group information and convert Multicast Group ID to real IP, run from any server which runs Mellanox OFED
7) ib-topology-viewer.sh - Provide a simple fabric topology high level outlook using switch to switch and switch to HCA total port connected count information, use this tool to look for miss cabling and CLOS topology violations.  Runs from OFED.
8) ib-trace-counter.sh - trace InfiniBand counter in unicast/multicast path from s source LID/hostname to a destination LID/hostname, run from any server which runs OFED 
9) ibtracert-v2.pl - trace InfiniBand path from a source hostname to a destination hostname, run from any server which runs OFED
10) Mellanox-disable-sm.pl - Disable all 4036/2036 Sm's for all switches according the ip addresses given in the file - run from any server
11) sysinfo-snapshot-3.1.8.tgz - Collects information on host in addition to performance tuning analyze, output is saved under /tmp/
12) sysinfo-diff-1.0.0.tgz - The sysinfo-diff tool compares between two Linux sysinfo-snapshot outputs, and places the comparison output into a tar file.

############
#4XXX TOOLS#
############

Download and copy the following tools to your ISR4XXX and run

1) show-running-config.pl - Extract the switch running configuration, run from any server 
2) get-switch-sn-snmp.sh - runs over a txt file containing ip addresses of Mellanox switches, and uses snmp to extract S/N of the switches in the txt file. (To be used with 4XXX switches only)

###############
#   UFM-API   #
###############
1) ufm-add-nodes-to-rack.py – Add given nodes (file or pattern) to a specific rack.
2) ufm-add-to-ls.py – Create/Add servers (guid file/hostname file) to specific logical server group
3) ufm-show-congestion-map.py – Show a real time congestion map of the fabric
4) ufm-dump-env.py – Dump an output of the components in the fabric
5) ufm-auto-update-switches-ip.py – In case no ufma on nodes or MC is disabled on MGMT network, some switch properties/ufm functionalities will not be recognized/available by/ UFM
6) get-fabric-pkeysTable.py - 
7) Reads a configuration from a given CSV file, and will load the configuration to UFM’s Event Management.
	(output event to: GUI?, LOG?, SNMP?, Threshold, Severity, etc….)
	An example of a .csv file eggs.csv (better to open with CSVed and not Excel)
	For example, you can run the script this way:
	python UpdateEventPolicyFromCsv.py
	This will use the default file location /opt/ufm/scripts/custom_policy.csv
	python UpdateEventPolicyFromCsv.py –s 172.24.4.1 -f /tmp/eggs.csv
	This way if you want are running the script from remote host and also need to specify a different location of the input file


###############
#   Windows   #
###############
1) Windows System Snapshot 2.3 - Collect information on host, zip output is saved by default under Desktop.
2) pciutils-3.1.9-1-win32 - Displays pci device status in Linux lspci style

