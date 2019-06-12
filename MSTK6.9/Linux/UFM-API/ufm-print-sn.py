#!/usr/bin/python
#
# Copyright (C) Mellanox Ltd. 2001-2010.  ALL RIGHTS RESERVED.
#
# This software product is a proprietary product of Mellanox Ltd.
# (the "Company") and all right, title, and interest and to the software product,
# including all associated intellectual property rights, are and shall
# remain exclusively with the Company.
#
# This software product is governed by the End User License Agreement
#
#Description:
#	Get fabric's switches SN
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


def Usage ():
    print
    print "Usage: %s [-s UFM REMOTE SERVER] [-u USER] [-p PASSWORD] [-v] [-h]"  % os.path.basename(sys.argv[0])
    print
    print "Options:"
    print "     [-s UFM REMOTE SERVER]      - Connect to remote UFM server"
    print "     [-u USER]                   - User to connect to UFM server"
    print "     [-p PASSWORD]               - Password to connect to UFM server"
    print "     [-v]                        - Show version "
    print "     [-h]                        - Show this help "
    print
    sys.exit(0)

try:
   opts, args = getopt.getopt(sys.argv[1:], "s:u:p:hv", ["help"])

except getopt.error :
   raise Usage()

for opt, arg in opts :
    if opt in ('-h', '--help'):
        Usage()
    if opt == '-u':
        user = arg
    if opt == '-p':
        password = arg
    elif opt == '-v':
        print os.path.basename(sys.argv[0]), "Version" , version
        sys.exit(2)
    elif opt == '-s':
        server = arg

#Connect to UFM server
UFMPort = connect(user, password, server)
siteSystems = UFMPort.site_systems('default')

for system in siteSystems:
        if system.systype in ("ISR4036", "ISR4036E"):
            # Gets all system's modules
            modules = UFMPort.site_device_modules("default", system.name)
	    for module in modules:
                if module.description == "system":
                    msg = "Name = %s, S/N = %s" % (system.dname, module.serial_number)
                    print "=" * len(msg)
                    print msg
                    print "=" * len(msg)
