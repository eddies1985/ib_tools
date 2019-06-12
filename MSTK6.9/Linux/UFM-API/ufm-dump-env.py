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
#    display logical model of the site according to the given level.
#    leve1 1 - Grid
#    level 2 - Environments and Networks
#    level 3 - Logical Servers
#    level 4 - Computes, NetIfcs
#    level 5 - Vifs, Flows

import sys
sys.path.append('/opt/ufm/gvvm/')

import string,os,getopt
from   client import connect, long2HexStr 
from   ws.UFM_client import UFMLocator

server=None
level=4
gridAttr = {'release':'release', 'networks_count':'networks count', 'environments_count':'environments count', 'license_functionality':'license' ,\
            'sys_start_time':'server start up time'}
user = 'admin'
password = '123456'
VMLocator = UFMLocator()
version=1.1

dump = 'all'
search_comp=""

def Usage ():
    print
    print "Usage: %s [-l LEVEL 1-5] [-s UFM REMOTE SERVER] [-u USER] [-p PASSWORD] [-v] [-h]"  % os.path.basename(sys.argv[0])
    print
    print "Options:"
    print "     [-l LEVEL 1-5]             - The hierarchy level of the logical model. default 4"
    print "     [-s UFM REMOTE SERVER]     - Connect to remote UFM server"
    print "     [-u USER]                  - User to connect to UFM server"
    print "     [-p PASSWORD]              - Password to connect to UFM server"
    print "     [-v]                       - Show version "
    print "     [-h]                       - Show this help "
    print

    sys.exit(1)


try:
   opts, args = getopt.getopt(sys.argv[1:], "l:s:u:p:hv", ["help"])

except getopt.error :
   raise Usage()

for opt, arg in opts :
    if opt == '-h':
        Usage()
    elif opt == '-u':
        user = arg
    elif opt == '-p':
        password = arg
    elif opt == '-l':
        if arg not in ['1', '2' ,'3' ,'4' ,'5']:
            Usage()
        level = int(arg)
    elif opt == '-v':
        print os.path.basename(sys.argv[0]), "Version" , version
        sys.exit(2)
    elif opt == '-s':
        server = arg

#connect to the UFM Server
UFMPort= connect(user, password, server)

site = UFMPort.sites_get('default')

grid = UFMPort.grid();
print "Grid:"
for k, v in grid.__dict__.items():
    if k in gridAttr:
        print "    %s: %s" %(gridAttr[k], v)
if level == 1:
    sys.exit(0)

compName={}
if level >= 4:
    for cmp in UFMPort.site_computers('default' ,False, False):
        compName[cmp.name]=cmp.dname

#get all networks
networks = UFMPort.networks()
if networks:
    print "\nNetworks: "
for net in networks:
    sl = 0
    if net.qos_params is not None:
        sl = net.qos_params.A2B_cos
    if site.isIB: 
        print ("   %-27s   pkey:%-11s  %s" %(net.to_string, net.p_key, sl))
    else:
        print ("   %-27s   vlan:%-11s  %s" %(net.to_string, net.vlan_tag, sl))

#get all environments
environments = UFMPort.environments()
if environments:
    print "\nEnvironments: "
    
#display the data according to the given level
for env in environments:
        print " "+env.to_string
        if level >= 3:
            servers=UFMPort.env_servers(str(env.name))
            if servers:
                print "   Logical servers:"
            for ls in servers:
                print "     "+ls.to_string, ls.state,ls.runsvc
                if level >= 4:
                    computes = UFMPort.env_ls_computes(str(env.name),str(ls.name))
                    if computes:
                        print "        Computes: "
                    for cm in computes :
                        print "           "+compName[cm.server],cm.mngip,cm.state
                        if level == 5:
                            for vi in UFMPort.env_ls_comp_vifs(str(env.name),str(ls.name),str(cm.name)):
                                print ("              %-8s   IPAddress %s" %(vi.name, vi.ip))
                            
                    netifcs = UFMPort.env_ls_interfaces(str(env.name), str(ls. name))
                    if netifcs:
                        print "        Network Interfaces: "
                        for ifc in netifcs:
                            if ifc.network == 'management':
                                continue
                            if ifc.qos_params:
                                sl= ifc.qos_params.A2B_cos
                            else:
                                sl = "default"
                            print "           network "+ifc.network+"       sl "+str(sl)+"        membership "+str(ifc.membership)
                            if level == 5:
                                flows = UFMPort.env_ls_netifc_flows(str(env.name), str(ls.name), str(ifc.name))
                                if flows:
                                    print "              Flows:"
                                    for flow in flows:
                                        print "                  source LS %s    source environment %s    destenation LS %s    source environment %s" \
                                        % (flow.src_lserver, flow.src_env, flow.dest_lserver, flow.dest_env)
                                        if flow.qos_params:
                                            print "                        A2B.cos %s    A2B.rate_limit %s    B2A.cos %s    B2A.rate_limit %s" \
                                            % (flow.qos_params.A2B_cos, flow.qos_params.A2B_rate_limit, flow.qos_params.B2A_cos, flow.qos_params.B2A_rate_limit)
                        

print
