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
#Used as follow:
# prints UFM congestion map values

#python imports
import sys
import os
import string
import getopt

#UFM imports
sys.path.append('/opt/ufm/gvvm/')

from client import connect,exception_string
from ws.UFM_client import UFMLocator

server=None  # Null for localhost
user = 'admin'
password = '123456'
version=1.1

def Usage ():
    print
    print "Usage: %s [-s UFM REMOTE SERVER] [-u USER] [-p PASSWORD] [-v] [-h]"  % os.path.basename(sys.argv[0])
    print
    print "Options:"
    print "     [-s UFM REMOTE SERVER]     - Connect to remote UFM server"
    print "     [-u USER]                  - User to connect to UFM server"
    print "     [-p PASSWORD]              - Password to connect to UFM server"
    print "     [-v]                       - Show version "
    print "     [-h]                       - Show this help "
    print

    sys.exit(1)


try:
   opts, args = getopt.getopt(sys.argv[1:], "s:u:p:hv", ["help"])

except getopt.error :
   raise Usage()

for opt, arg in opts :
    if opt == '-h':
        Usage()
    elif opt == '-u':
        user = arg
    elif opt == '-p':
        password = arg
    elif opt == '-v':
        print os.path.basename(sys.argv[0]), "Version" , version
        sys.exit(2)
    elif opt == '-s':
        server = arg

#connect to UFM server
try:
    UFMPort = connect(user, password, server)
except Exception, exc:
    print "Can't connect ",server


# read congestion map object
cmap = UFMPort.monitor_congestion_map()

#prints congestion map data
print " Bar          Tier1      Tier2      Tier3      Tier4"
print '='*56

for i in [0,1,2,3,4,5] :  # changing the order of the numbers will change the row order
     print " %-10s %10d %10d %10d %10d" % \
             (cmap[1].couple[i].name[10:], cmap[1].couple[i].value, cmap[1].couple[i].value, cmap[2].couple[i].value, cmap[3].couple[i].value)
