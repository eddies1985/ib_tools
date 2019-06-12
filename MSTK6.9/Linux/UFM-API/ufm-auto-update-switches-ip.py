#!/usr/bin/python
#
#Description:
#	Add IB switches IP addresses manually to UFM, in cases where MC is disbaled on MGMT network
#	Written by eladh@mellanox.com

import sys,string,os,getopt,time
sys.path.append('/opt/ufm/gvvm/')

from   client import GVC, GVSimple, connect
from   ws.UFM_client import UFMLocator

server = None  # Null for localhost
user = 'admin'
password = '123456'
version = 1.3
VMLocator = UFMLocator()
input_lines = []
inputFile = "None"
switch_guid = None
switch_ip = None
deviceExists = True
siteSystems = None
uniqueArray = []
isHostname = False
hostName = None

def Usage ():
    print
    print "Usage: %s [-s UFM REMOTE SERVER] [-u USER] [-p PASSWORD] [-g /path/to/GUID-file] [-n /path/to/Hostname-file] [-v] [-h]"  % os.path.basename(sys.argv[0])
    print
    print "Example 1: ./ufm-auto-update-switches-ip.py -g /tmp/switchGuid.txt"
    print "Example 2: ./ufm-auto-update-switches-ip.py -s 172.24.4.1 -u admin -p 123456 -n /tmp/switchName.txt"
    print
    print
    print "switchGuid.txt Example:"
    print "0008f10500100322 172.24.3.2"
    print "0008f10500100317 172.24.4.183"
    print "..."
    print
    print "switchName.txt Example:"
    print "4036-1 172.24.3.2"
    print "IS5030.localsite 172.24.4.183"
    print "..."
    print
    print
    print "Options:"
    print "     [-s UFM REMOTE SERVER]      - Connect to remote UFM server"
    print "     [-u USER]                   - User to connect to UFM server"
    print "     [-p PASSWORD]               - Password to connect to UFM server"
    print "     [-g /path/to/GUID-file]     - Input file containing Switches Guids and Switches IP Addresses"
    print "     [-n /path/to/Hostname-file] - Input file containing Switches Hostnames and Switches IP Addresses"
    print "     [-v]                        - Show version "
    print "     [-h]                        - Show this help "
    print
    sys.exit(0)

try:
   opts, args = getopt.getopt(sys.argv[1:], "s:u:p:g:n:hv", ["help"])

except getopt.error :
   raise Usage()

for opt, arg in opts :
    if opt in ('-h', '--help'):
        Usage()
    if opt == '-u':
        user = arg
    if opt == '-p':
        password = arg
    if opt == '-n':
        isHostname = True
        inputFile = arg
    if opt == '-g':
        inputFile = arg
    elif opt == '-v':
        print os.path.basename(sys.argv[0]), "Version" , version
        sys.exit(2)
    elif opt == '-s':
        server = arg

#Validate IP Address format
def ipFormatChk(ip_str):
    if len(ip_str.split()) == 1:
        ipList = ip_str.split('.')
        if len(ipList) == 4:
            for i, item in enumerate(ipList):
                try:
                    ipList[i] = int(item)
                except:
                    return False
                if not isinstance(ipList[i], int):
                    return False
            if max(ipList) < 256:
                return True
            else:
                return False
        else:
            return False
    else:
        return False


#Connect to UFM server
UFMPort = connect(user, password, server)
siteSystems = UFMPort.site_systems('default')

#Open input file for reading, insert lines from file to an array.
try:
    f = open(inputFile,'r')
except (RuntimeError, IOError):
    print "\033[1;31mError: can\'t find file or read data\n\033[1;m"
    Usage()
else:
    input_lines = f.readlines()
    f.close()

#Remove spaces and newline characters
for line in range(len(input_lines)):
    input_lines[line] = input_lines[line].strip('\n').strip(' ')
if ('' in input_lines):
        input_lines.remove('')

#Check no duplicate GUIDS given in the input file
for line in input_lines:
    if not line.split(' ',1)[0] in uniqueArray:
        uniqueArray.append(line.split(' ',1)[0])
    else:
        print '\033[1;31mDuplicae GUID found \033[1;m', line, '\033[1;31mTerminating...\033[1;m'
        sys.exit(0)

#Check no duplicate IP Addresses given in the input file
for line in input_lines:
    if not line.split(' ',1)[1] in uniqueArray:
        uniqueArray.append(line.split(' ',1)[1])
    else:
        print '\033[1;31mDuplicae IP Address found \033[1;m', line, '\033[1;31mTerminating...\033[1;m'
        sys.exit(0)
   
#Update UFM IB switches IP addresses
for line in range(len(input_lines)):
    #Validate each line contains two fields only
    if (len(string.split(input_lines[line])) != 2):
        print '\033[1;31mLine number\033[1;m', line+1, '\033[1;31mcontains wrong format, skipping...\n\033[1;m'
        continue
    
    if (isHostname == False):
        switch_guid = input_lines[line].split(' ',1)[0].strip('\n').strip(' ')
        switch_ip = input_lines[line].split(' ',1)[1].strip('\n').strip(' ')
    elif (isHostname == True):
        hostName = input_lines[line].split(' ',1)[0].strip('\n').strip(' ')
        for device in siteSystems:
            if hostName == device.dname:
                switch_guid = device.name.strip('\n').strip(' ')
        switch_ip = input_lines[line].split(' ',1)[1].strip('\n').strip(' ')

    #Check IP is in correct format
    if (ipFormatChk(switch_ip) == False):
        print '\033[1;31mIP Address in line number\033[1;m', line + 1, '\033[1;31mis invalid, skipping...\n\033[1;m'
        continue

    #Validate the GUID of the given switch is found in the fabric
    deviceExists = False
    for device in siteSystems:
        if device.name == switch_guid:
            deviceExists = True
            #Get switch identificationProp object
            identificationProp = UFMPort.site_device_getIdentificationProp('default', switch_guid)
            #Change identificationProp object
            identificationProp.is_manual_ip = True
            print '\033[1;32mSwitch number\033[1;m', line + 1
            if (isHostname == True):
                print "Switch Name:", hostName
            print "Switch", switch_guid, "is set for manual IP"
            identificationProp.manual_ip = switch_ip
            print "IP Address", switch_ip, "is set for switch", switch_guid, "\n"
            #Update (override) switch identificationProp
            UFMPort.site_device_update_identificationProp('default', switch_guid, identificationProp)
            break

    #Check if last line was not added to UFM
    if (deviceExists == False):
        print '\033[1;31mGUID in line number\033[1;m', line + 1, '\033[1;31mcan not be found in the fabric, skipping...\n\033[1;m'
