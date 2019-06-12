#!/usr/bin/python
"""
@copyright:
        Copyright (C) Mellanox Technologies Ltd. 2001-2012.  ALL RIGHTS RESERVED.

        This software product is a proprietary product of Mellanox Technologies Ltd.
        (the "Company") and all right, title, and interest in and to the software product,
        including all associated intellectual property rights, are and shall
        remain exclusively with the Company.

        This software product is governed by the End User License Agreement
        provided with the software product.
"""
__docformat__ = "javadoc"

# Used as follow
#
# If network does not exist, create it with random pkey and ip address
# If environment does not exist, create it
# If LS does not exist, create it
# Connect LS to network
# Allocate nodes specified by guid in GUIDS FILE
#

#python imports
import sys
import os
import getopt
import string

#UFM imports
sys.path.append('/opt/ufm/gvvm/')

from client import connect, GVC, GVSimple, long2HexStr
from   ws.UFM_client import UFMLocator

server=None  # Null for localhost
user='admin'
password='123456'
version=1.1
env_name=""
ls_name=""
file_flag=""
input_file=""
independence_flag = False
guid_hostname_file = None
machine = 'physical'
vmm_group = ''

def Usage ():
    print
    print "Usage: %s -e ENVIRONMENT_NAME -l LOGICAL_SERVER [-g GUIDS FILE | -n HOSTNAME FILE] [-s UFM REMOTE SERVER] [-u USER] [-p PASSWORD]\
[-I GUID HOSTNAME FILE] [-v] [-h]"  % os.path.basename(sys.argv[0])
    print
    print "Options:"
    print "     -e ENVIRONMENT NAME        - Environment name"
    print "     -l LOGICAL SERVER NAME     - Logical Server to remove"
    print "     -g GUIDS/MACS FILE         - File contains GUIDs or MACs to add the LS"
    print "     -n HOSTNAME FILE           - File contains hostnames to add the LS"
    print "     {-m VMM GROUP]             - Create Logical VM" 
    print "     [-s UFM REMOTE SERVER]     - Connect to remote UFM server"
    print "     [-I GUID HOSTNAME FILE]    - Work in Bypass mode. See user manual for more information"
    print "     [-u USER]                  - User to connect to UFM server"
    print "     [-p PASSWORD]              - Password to connect to UFM server"
    print "     [-v]                       - Show version "
    print "     [-h]                       - Show this help "
    print

    sys.exit(1)


try:
   opts, args = getopt.getopt(sys.argv[1:], "s:e:l:g:n:I:u;p;m:hv", ["help"])

except getopt.error :
   raise Usage()

for opt, arg in opts :
    if opt == '-e':
        env_name = arg
    elif opt == '-l':
        ls_name = arg
    elif opt == '-g':
        file_flag = opt
        input_file = arg
    elif opt == '-n':
        input_file = arg
        file_flag = opt
    elif opt == '-I':
        independence_flag = True
        guid_hostname_file = arg
    elif opt == '-m':
        machine='vmware'
        vmm_group = arg
    elif opt == '-u':
        user = arg
    elif opt == '-p':
        password = arg
    elif opt in ('-h', '--help'):
        Usage()
    elif opt == '-v':
        print os.path.basename(sys.argv[0]), "Version" , version
        sys.exit(2)
    elif opt == '-s':
        server = arg

if (env_name == "" or ls_name == "" or file_flag == "" or input_file == ""):
        Usage()
if independence_flag and not os.path.exists(guid_hostname_file):
        Usage()

input_lines = []

f = None                     # init fout for same reason
try:                            # file IO is "dangerous"
  f = open(input_file,'r',) # open output.txt, mode as in c fopen
except IOError, e:              # catch IOErrors, e is the instance
  print "Error in file IO: ", e # print exception info if thrown

input_lines = f.readlines()

for line in range(len(input_lines)):
        input_lines[line] = input_lines[line].strip('\n')
        input_lines[line] = input_lines[line].strip(' ')

if ('' in input_lines):
        input_lines.remove('')


f.close()

if len (input_lines) == 0:
    print 'No lines in input file'
    sys.exit(1)

#connect to UFM server
UFMPort= connect(user, password, server)

#if Independence mode selected and site is eth exit 
site=UFMPort.sites_get('default')
if independence_flag and not site.isIB:
    print "Bypass mode is not valid for eth sites"
    Usage()

#check that the given environmet exist
if UFMPort.environments_get(env_name) is None:
        print "Environment %s doesn't exists" % env_name
        sys.exit(1)

print 'Environment %s exists' % env_name

#sets the devices of the site. it in Independence mode then use guid hostname file
site_devices = []
if independence_flag:
    try:
        fd = open(guid_hostname_file,"r")
        s = string.rstrip(fd.readline(), '\n')
        while s:
            s1 = s.split(" ")
            if len(s1) > 1:
                dev = GVC(otype = "Computer", name = s1[0], dname = s1[1], usedby = "") 
                site_devices.append(dev)
            s = string.rstrip(fd.readline(), '\n')
        fd.close()
    except Exception, exc:
        print "GUID HOSTNAME FILE is not in the proper form. please see manual"
        sys.exit(1)
else:
    site_devices = UFMPort.site_systems('default')


if machine == 'physical':
    needed_otype = 'Computer'
else:
    needed_otype = 'VM' 

if file_flag == '-g':
   # Create device list
   devices=[]
   for i in range(len(input_lines)):
        site_found = 0
        for dev in site_devices:
                if (dev.otype == needed_otype) and (input_lines[i] == str(dev.name)):
                        if (dev.usedby != '') :
                                print input_lines[i] + " is already assigned to another LS"
                                site_found = 1
                                break
                        else:
                                devices.append(dev)
                                site_found = 1
                                break
# this host does not exist
        if site_found == 0:
                print 'Node %s does not exist' % input_lines[i]

if file_flag == '-n':
# Create device list
   devices=[]
   for i in range(len(input_lines)):
        site_found = 0
        for dev in site_devices:
                if dev.otype == needed_otype:
                   name_buf = str(dev.dname)
                   if site.isIB:
                       name =  name_buf.split(" ")[0].split(".")
                       dev_name = name[0]
                   else:
                       dev_name = name_buf
                   if input_lines[i] == dev_name:
                        if (dev.usedby != '') :
                                print input_lines[i] + " is already assigned to another LS"
                                site_found = 1
                                break
                        else:
                                devices.append(dev)
                                site_found = 1
                                break
    # this host does not exist
        if site_found == 0:
                print 'Node %s does not exist' % input_lines[i]

print ("creating devices list")

# If LS does not exist, create it. if it exist, update it
ls_exists = False
try:
        ls = UFMPort.env_servers_get(env_name, ls_name)
        ls_exists = True
        print 'LS %s exists. Updating...' % ls_name
        ls = UFMPort.env_servers_update(env_name, GVC(name = ls_name, description = "Created by UFM SDK", \
                                                is_cluster = 1, resource_count = ls.resource_count + len(devices), services_count = 0, interfaces_count = 0, \
                                                computes_count = 0, ldisks_count = 0, machine = machine, provisioning_method = 'external', \
                                                vmm_group_name = vmm_group))
except Exception, exc:
        if ls_exists:
            print "Couldn't update LS. if update a VM group make sure the VMM group is valid"
            sys.exit(1)
        else:
            print 'LS %s does not exist. Creating...' % ls_name
            try:
                ls = UFMPort.env_servers_add(env_name, GVC(name = ls_name, description = "Created by UFM SDK", \
                                                    is_cluster = 1, resource_count = len(devices), services_count = 0, interfaces_count = 0, \
                                                    computes_count = 0, ldisks_count = 0, machine = machine, provisioning_method = 'external', \
                                                    vmm_group_name = vmm_group))
            except Exception, exc:
                print "Couldn't create LS. if create a VM group make sure the VMM group is valid"
                sys.exit(1)

if (len(devices) == 0):
        print 'it appears that the file provided did not contain any nodes'
        print 'No nodes were allocated for logical server %s' % (ls_name)
        sys.exit(1)

# Allocate resources
try:
        nodes_num = UFMPort.env_ls_allocate( env_name, ls_name, len(input_lines), "running", devices)
        print '\n%d nodes were allocated for logical server %s' % (nodes_num, ls_name)

except Exception, exc:
            print 'Allocation exception'
            if 'was not found in the VMM group' in str(exc):
                print 'some of the given VMs are were not found in the VMM group given'
            sys.exit(1)   

