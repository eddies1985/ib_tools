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

#
#performs the following flow:
#    get site's devices.
#    select the ones fitting the paternn
#    creates new rack
#    assign the proper nodes to the rack

#python imports
import sys
import string
import os
import getopt

#UFM imports
sys.path.append('/opt/ufm/gvvm/')

from client import connect ,GVC
from ws.UFM_client import UFMLocator

def Usage ():
        print
        print "Usage: %s -r RACKNAME -n NODES PATTERN [-t GROUP TYPE] [-s UFM REMOTE SERVER] [-I GUID HOSTNAME FILE] [-u USER] [-p PASSWORD]\
[-v] [-h]"  % os.path.basename(sys.argv[0])
        print
        print "Options:"
        print "     -r RACK NAME            - Specify the Rack name"
        print "     -n NDOE PATTERN         - Node Pattern that will be added to the Rack"
        print "     [-t GROUP TYPE]         - One of Rack, VMM_Group. default - Rack"
        print "     [-s UFM REMOTE SERVER]  - Connect to remote UFM server"
        print "     [-I GUID HOSTNAME FILE] - Work in Bypass mode. See user manual for more information"
        print "     [-u USER]               - User to connect to UFM server"
        print "     [-p PASSWORD]           - Password to connect to UFM server"
        print "     [-v]                    - Show version "
        print "     [-h]                    - Show this help "
        print
        sys.exit(1)

rackName=""
pattern=""
rackFound=False
nodeFound=False
independence_flag=False
guid_hostname_file = None
rackType = 'Rack'
guids_or_macs=[]
server=None
user='admin'
password='123456'
version=1.1

try:
        opts, args = getopt.getopt(sys.argv[1:], "r:n:t:s:I:u:p:hv", ["help"])
except getopt.error :
   raise Usage()

for opt, arg in opts :
        if opt == '-h':
                Usage()
        elif opt == '-r':
                rackName=arg
        elif opt == '-n':
                pattern=arg
        elif opt == '-I':
            independence_flag = True
            guid_hostname_file = arg
        elif opt == '-u':
            user = arg
        elif opt == '-t':
            if arg not in ['Rack', 'VMM_Group']:
                Usage()
            rackType = arg
        elif opt == '-p':
            password = arg
        elif opt == '-v':
                print os.path.basename(sys.argv[0]), "Version" , version
                sys.exit(0)
        elif opt == '-s':
                server = arg
if ((pattern == "") or (rackName == "")):
        Usage()
#check that the given guid_hostname_file exist
if independence_flag and not os.path.exists(guid_hostname_file):
        print "GUID HOSTNAME FILE doesn't exists"
        Usage()

#connect to the UFM Server
VMLocator = UFMLocator()
UFMPort=connect(user, password, server)

#if Independence mode selected and site is eth exit 
site=UFMPort.sites_get('default')
if independence_flag and not site.isIB:
    print "Bypass mode is not valid for eth sites"
    Usage()
if rackType == 'VMM_Group' and site.isIB:
    print "VMM_Group not valid on InfiniBand fabrics"
    Usage() 

#create new rack object
newRack=GVC(rackName,description='', typ=rackType)

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

#check if the given new rack name already exist
if rackType == 'Rack':
    notRackType = 'VMM_GROUP'
else:
    notRackType = 'Rack'
for g in UFMPort.site_groups('default', notRackType):
    if (g.name == rackName):
        print "There is already a group %s of type %s" % (rackName, notRackType)
        sys.exit(1)
    
for g in UFMPort.site_groups('default', rackType):
        if (g.name == rackName):
                rackFound = True

#add the new rack
if ( not rackFound ):
        print
        print "%s %s doesn't exist, Creating %s...." % (rackType, rackName, rackType)
        UFMPort.site_groups_add('default', rackType ,newRack)

print
print "Adding the following nodes to",rackName
print

#check for node fitting the given pattern
for dev in site_devices:
        if (pattern in dev.dname) :
                nodeFound = True
                guids_or_macs += [dev.name]
                if site.isIB:
                    print '    ',dev.dname,'GUID:',dev.name
                else:
                    print '    ',dev.dname,'MAC:',dev.name

#assign nodes to the reck
if nodeFound :
    try:
        UFMPort.site_group_add_devices('default', rackName, rackType, guids_or_macs)
        print
        print "Done."
    except Exception, exc:
        print
        print "couldn't group given hosts. Make sure they are in the site"
        if rackType == 'VMM_Group':
            print "Also make sure that the given devices are VMM" 
else:
        print "No matches."

print
