#!/usr/bin/python

#python imports
import sys
import os
import getopt
import string

#UFM imports
sys.path.append('/opt/ufm/gvvm/')

from client import connect, GVC, GVSimple, long2HexStr
from ws.UFM_client import UFMLocator


server=None  # Null for localhost
user='admin'
password='123456'
version=1.0
environment=''
logical_server_group=''
numof_allocated_nodes=''
input_lines=[]
devices=[]


#connect to UFM server
UFMPort= connect(user, password, server)
site_devices = UFMPort.site_systems('default')
os.system("rm -rf /tmp/pkeysTable")

for device in site_devices:
	if (device.otype == 'Computer'):
		os.system("echo "" >> /tmp/pkeysTable")
		os.system("echo %s >> /tmp/pkeysTable" % (device.dname))
		os.system("echo %s >> /tmp/pkeysTable" % (device.name))
		os.system("echo "" >> /tmp/pkeysTable")
		os.system("smpquery PKeyTable %s >> /tmp/pkeysTable" % (device.name))

print "File created successfully - /tmp/pkeysTable"
