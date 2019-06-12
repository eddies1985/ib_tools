#!/usr/bin/env python
#
## # Copyright (C) Mellanox Ltd. 2001-2016.  ALL RIGHTS RESERVED.
#
# This software product is a proprietary product of Mellanox Ltd.
# (the "Company") and all right, title, and interest and to the software product,
# including all associated intellectual property rights, are and shall
# remain exclusively with the Company.
#
# This software product is governed by the End User License Agreement
# provided with the software product.
#
#
# This scripts supports the below Mellanox Switch Devices:
# 1. InfiniScale IV (IS4)
# 2. SwitchX / SwitchX-2
# 3. SwitchIB
#

# This script will change the Names of Unmanaged Mellanox switches from:
# 1. given GUID to Name file
# 2. Single switch/port Guid and a name
# 3. Single Lid and a name
# 4. This name change is not boot persistent
# Dependencies:  python, mft, infiniband-diags  
#
# Note - For SwitchX/SwitchIB the Tool supports only GA FW releases 
# 

import sys
import os
import array
import subprocess
import re
import time
from optparse import OptionParser

#Constant strings

CA = "mlx4_0"
Port = "1"

mstDevLid = 0 
mstDevCa = CA
mstDevPort = Port
switchQuery = {}


defaultPadding = "_"
smpquery_n_Guid = None
smpquery_ni_lid   = None
smpquery_si_Guid  = None
smpquery_si_lid   = None
smpquery_pi_Guid  = None
smpquery_pi_lid   = None
smpquery_nd_Guid  = None
smpquery_nd_lid   = None

cr_access_lid = "mcra lid-"
cr_access_mst = "mcra "
flint_lid     = "flint -d lid-"
flint = "flint -d"
VendorId_Mellanox = "0x0002c9"
DevId_SwitchIB = "0xcb20"
DevId_SX = "0xc738"
DevId_IS4 = "0xbd36"
DevId = ""
mstDev = ""

fwVer = ""
padding = defaultPadding
SW_PSID = None
showPsid = False
File_Mapping = None

IS4_node_description = [ "0x672ac.0", "0x672b0.0", "0x672b4.0", "0x672b8.0", "0x672bc.0", "0x672c0.0", "0x672c4.0", "0x672c8.0", "0x672cc.0", "0x672d4.0", "0x672d8.0", "0x672dc.0", "0x672e0.0", "0x672e4.0", "0x672e8.0" ]



#SwitchX cr-space Node_Desc Swid_0 address per GA fw release

SwitchX = {}

SwitchX["9.3.8000"] =  [ "0x6fac0.0", "0x6fac4.0", "0x6fac8.0", "0x6facc.0", "0x6fad0.0", "0x6fad4.0", "0x6fad8.0", "0x6fadc.0", "0x6fae0.0", "0x6fae4.0", "0x6fae8.0", "0x6aec.0", "0x6faf0.0", "0x6faf4.0", "0x6faf8.0", "0x6fafc.0"]
SwitchX["9.3.6000"] =  [ "0x6fac0.0", "0x6fac4.0", "0x6fac8.0", "0x6facc.0", "0x6fad0.0", "0x6fad4.0", "0x6fad8.0", "0x6fadc.0", "0x6fae0.0", "0x6fae4.0", "0x6fae8.0", "0x6aec.0", "0x6faf0.0", "0x6faf4.0", "0x6faf8.0", "0x6fafc.0"]
SwitchX["9.3.4000"] =  [ "0x6fa74.0", "0x6fa78.0", "0x6fa7c.0", "0x6fa80.0", "0x6fa84.0", "0x6fa88.0", "0x6fa8c.0", "0x6fa90.0", "0x6fa94.0", "0x6fa98.0", "0x6fa9c.0", "0x6aa0.0", "0x6faa4.0", "0x6faa8.0", "0x6faac.0", "0x6fab0.0"]
SwitchX["9.3.2000"] =  [ "0x6fa74.0", "0x6fa78.0", "0x6fa7c.0", "0x6fa80.0", "0x6fa84.0", "0x6fa88.0", "0x6fa8c.0", "0x6fa90.0", "0x6fa94.0", "0x6fa98.0", "0x6fa9c.0", "0x6aa0.0", "0x6faa4.0", "0x6faa8.0", "0x6faac.0", "0x6fab0.0"]
SwitchX["9.3.0"] =  [ "0x6faf0.0", "0x6faf4.0", "0x6faf8.0", "0x6fafc.0", "0x6fb00.0", "0x6fb04.0", "0x6fb08.0", "0x6fb0c.0", "0x6fb10.0", "0x6fb14.0", "0x6fb18.0", "0x6fb1c.0", "0x6fb20.0", "0x6fb24.0", "0x6fb28.0", "0x6fb2c.0"]
SwitchX["9.2.8000"] = [ "0x6faf0.0", "0x6faf4.0", "0x6faf8.0", "0x6fafc.0", "0x6fb00.0", "0x6fb04.0", "0x6fb08.0", "0x6fb0c.0", "0x6fb10.0", "0x6fb14.0", "0x6fb18.0", "0x6fb1c.0", "0x6fb20.0", "0x6fb24.0", "0x6fb28.0", "0x6fb2c.0"]
SwitchX["9.2.6100"] = [ "0x6FB70.0", "0x6FB74.0", "0x6FB78.0", "0x6FB7C.0", "0x6FB80.0", "0x6FB84.0", "0x6FB88.0", "0x6FB8C.0", "0x6FB90.0", "0x6FB94.0", "0x6FB98.0", "0x6FB9C.0", "0x6FBA0.0", "0x6FBA4.0", "0x6FBA8.0", "0x6FBAC.0"]
SwitchX["9.2.4002"] = [ "0x6FB88.0", "0x6FB8C.0", "0x6FB90.0", "0x6FB94.0", "0x6FB98.0", "0x6FB9C.0", "0x6FBA0.0", "0x6FBA4.0", "0x6FBA8.0", "0x6FBAC.0", "0x6FBB0.0", "0x6FBB4.0", "0x6FBB8.0", "0x6FBBC.0", "0x6FBC0.0", "0x6FBC4.0"]
SwitchX["9.2.3000"] = [ "0x6fae8.0", "0x6faec.0", "0x6faf0.0", "0x6faf4.0", "0x6faf8.0", "0x6fafc.0", "0x6fb00.0", "0x6fb04.0", "0x6fb08.0", "0x6fb0c.0", "0x6fb10.0", "0x6fb14.0", "0x6fb18.0", "0x6fb1c.0", "0x6fb20.0", "0x6fb24.0"]
SwitchX["9.2.0"] = [ "0x6fae8.0", "0x6faec.0", "0x6faf0.0", "0x6faf4.0", "0x6faf8.0", "0x6fafc.0", "0x6fb00.0", "0x6fb04.0", "0x6fb08.0", "0x6fb0c.0", "0x6fb10.0", "0x6fb14.0", "0x6fb18.0", "0x6fb1c.0", "0x6fb20.0", "0x6fb24.0"]
SwitchX["9.1.7000"] = [ "0x6faa8.0", "0x6faac.0", "0x6fab0.0", "0x6fab4.0", "0x6fab8.0", "0x6fabc.0", "0x6fac0.0", "0x6fac4.0", "0x6fac8.0", "0x6facc.0", "0x6fad0.0", "0x6fad4.0", "0x6fad8.0", "0x6fadc.0", "0x6fae0.0", "0x6fae4.0"]


SwitchIB = {}
SwitchIB["11.0300.0354"] = [ "0x8dcd4.0", "0x8dcd8.0", "0x8dcdc.0", "0x8dce0.0", "0x8dce4.0", "0x8dce8.0", "0x8dcec.0", "0x8dcf0.0", "0x8dcf4.0", "0x8dcf8.0", "0x8dcfc.0", "0x8dd00.0", "0x8dd04.0", "0x8dd08.0", "0x8dd0c.0", "0x8dd10.0" ]
SwitchIB["11.0200.0124"] = [ "0x8dcbc.0", "0x8dcc0.0", "0x8dcc4.0", "0x8dcc8.0", "0x8dccc.0", "0x8dcd0.0", "0x8dcd4.0", "0x8dcd8.0", "0x8dcdc.0", "0x8dce0.0", "0x8dce4.0", "0x8dce8.0", "0x8dcec.0", "0x8dcf0.0", "0x8dcf4.0", "0x8dcf8.0" ]
SwitchIB["11.0200.0120"] = [ "0x8dcb8.0", "0x8dcbc.0", "0x8dcc0.0", "0x8dcc4.0", "0x8dcc8.0", "0x8dccc.0", "0x8dcd0.0", "0x8dcd4.0", "0x8dcd8.0", "0x8dcdc.0", "0x8dce0.0", "0x8dce4.0", "0x8dce8.0", "0x8dcec.0", "0x8dcf0.0", "0x8dcf4.0" ]
SwitchIB["11.0100.0112"] = [ "0x89d3c.0", "0x89d40.0", "0x89d44.0", "0x89d48.0", "0x89d4c.0", "0x89d50.0", "0x89d54.0", "0x89d58.0", "0x89d5c.0", "0x89d60.0", "0x89d64.0", "0x89d68.0", "0x89d6c.0", "0x89d70.0", "0x89d74.0", "0x89d78.0" ]
SwitchIB[ "11.1.1002"  ] = [ "0x8a334.0", "0x8a338.0", "0x8a33c.0", "0x8a340.0", "0x8a344.0", "0x8a348.0", "0x8a34c.0", "0x8a350.0", "0x8a354.0", "0x8a358.0", "0x8a35c.0", "0x8a360.0", "0x8a364.0", "0x8a368.0", "0x8a36c.0", "0x8a370.0" ] 
SwitchIB[ "11.1.1000"  ] = [ "0x8a334.0", "0x8a338.0", "0x8a33c.0", "0x8a340.0", "0x8a344.0", "0x8a348.0", "0x8a34c.0", "0x8a350.0", "0x8a354.0", "0x8a358.0", "0x8a35c.0", "0x8a360.0", "0x8a364.0", "0x8a368.0", "0x8a36c.0", "0x8a370.0" ]

SwitchIB_PSID = { "MT_1880110032" : "MSB7790-E" ,
					"LNV1880110032" : "00KH883_00KH888_Ax" 
				}

SwitchX_PSID = { "MT_1260110020" : "MSX6015F_xxS" ,
				 "MT_1260110029" : "MSX6015T_xxS" ,
				 "MT_1010110021" : "MSX6025F_xxxR_A1"  ,
				 "MT_1010210021" : "MSX6025F_xxxR_B1_B4" ,
				 "MT_1010310021" : "MSX6025F-xxxS" ,
				 "MT_1010110026" : "MSX6025T_xxxR_A1" ,
				 "MT_1010210026" : "MSX6025T_xxxR_B1_B3",
				 "MT_1010310026" : "MSX6025T-xxxS" ,
				 "MT_1260110021" : "MSX6005F-xxxS" ,
				 "MT_1260110026" : "MSX6005T-xxxS" ,
				 "HP_1010110021" : "670768-B21",
				 "HP_1010310026" : "712495-B21_712496-B21",
				 "HP_0260120021" : "648312-B21"
				}

IS4_PSID	 = { "MT_0FB0110003" : "MIS5022Q" ,
				 "MT_0F90110002" : "MIS5023Q" ,
				 "MT_0F80110002" : "MIS5024Q" ,
				 "MT_0D00110002" : "MIS5025D" ,
				 "MT_0D00110003" :"MIS5025Q"
				}
				


				
# 9.2.4002 Addresses
# SX_node_description  =[ "0x6FB88.0","0x6FB8C.0","0x6FB90.0","0x6FB94.0","0x6FB98.0","0x6FB9C.0","0x6FBA0.0","0x6FBA4.0","0x6FBA8.0","0x6FBAC.0","0x6FBB0.0","0x6FBB4.0","0x6FBB8.0","0x6FBBC.0","0x6FBC0.0","0x6FBC4.0" ]
SX_PSID_Unmanaged    = [ "MT_1010110021", "MT_1010110026","MT_1010210021" ,"MT_1010210026","HP_1010110021"]
IS4_PSID_Unmanaged   = [ "MT_0D00110003", "MT_0D00110002", "MT_0F80110002", "MT_0F90110002", "MT_0FB0110003", "MT_0C20110003", "ISL0F80000003","ISL0F90000003" ,"ISL0FB0000003","ISL0D00000003"]

def Command_syntax():
	global smpquery_ni_Guid
	global smpquery_ni_lid  
	global smpquery_si_Guid 
	global smpquery_si_lid  
	global smpquery_pi_Guid 
	global smpquery_pi_lid
	global smpquery_nd_Guid
	global smpquery_nd_lid
	global cr_access_lid 
	smpquery_ni_Guid = "smpquery ni -C " + CA + " -P " + Port + " -G "
	smpquery_ni_lid  = "smpquery ni -C " + CA + " -P " + Port + " "
	smpquery_si_Guid = "smpquery si -C " + CA + " -P " + Port + " -G "
	smpquery_si_lid  = "smpquery si -C " + CA + " -P " + Port + " "
	smpquery_pi_Guid = "smpquery pi -C " + CA + " -P " + Port + " -G "
	smpquery_pi_lid  = "smpquery pi -C " + CA + " -P " + Port + " "
	smpquery_nd_Guid = "smpquery nd -C " + CA + " -P " + Port + " -G "
	smpquery_nd_lid  = "smpquery nd -C " + CA + " -P " + Port + " "
	cr_access_lid = "mcra lid-"
	

########################################################################################################################
#Classes
class bcolors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'


#Functions

def NodeInfo(Lid_based,Address,Attribute):

	# print Lid_based
	# print Address
	# print Attribute
# compose the smpquery ni command according to Lid_based or Guid_Based and the required Attribute   
	if Lid_based == True:
		cmd =smpquery_ni_lid + str(Address) + '| grep -e ^' + str(Attribute)
	else:
		cmd =smpquery_ni_Guid +' '+ str(Address) + '| grep -e ^' + str(Attribute)
	#print cmd
        # Put stderr and stdout into pipes
	try:
		proc = subprocess.Popen(cmd,shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE)
		return_code = proc.wait()
        # Read from pipes
	except:
		print ("Something went wrong while trying to get the Node Info")
		if proc.stderr !=None:
			for line in proc.stderr:
				print bcolors.FAIL + line.rstrip() + bcolors.ENDC
		return "Error"
		 
	for line in proc.stdout:
		result = line.rstrip()
		result = result.replace(".","")
		result = result.replace(Attribute+":","")
		return result

############################################################################################################### 
def SwitchInfo(Lid_based,Address,Attribute):
	# compose the smpquery si command according to Lid_based or Guid_Based and the required Attribute
	if Lid_based == True:
		cmd =smpquery_si_lid + str(Address) + '| grep -e ^' + str(Attribute)
	else:
		cmd =smpquery_si_Guid +' '+ str(Address) + '| grep -e ^' + str(Attribute)
	# Put stderr and stdout into pipes
	try:
		proc = subprocess.Popen(cmd,shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE)
		return_code = proc.wait()
	# Read from pipes
	except:
		print "Something went wrong while trying to get the Node Info"
		if proc.stderr !=None:
			for line in proc.stderr:
				print bcolors.FAIL + line.rstrip() + bcolors.ENDC
			return "Error"
	for line in proc.stdout:
		result = line.rstrip()
		result = result.replace(".","")
		result = result.replace(Attribute+":","")
		return result
	
###############################################################################################################

def PortInfo(Lid_based,Address,port,Attribute):
	
	if Lid_based == True:
		cmd =smpquery_pi_lid + str(Address) + ' ' + str(port) + ' | grep -e ^' + str(Attribute)
	else:
		cmd =smpquery_pi_Guid +' '+ str(Address) + ' ' + str(port) + ' | grep -e ^' + str(Attribute)
	# Put stderr and stdout into pipes
	try:
		proc = subprocess.Popen(cmd,shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE)
		return_code = proc.wait()
	# Read from pipes
	except:
		print "Something went wrong while trying to get the Port Info"
		if proc.stderr !=None:
			for line in proc.stderr:
				print bcolors.FAIL + line.rstrip() + bcolors.ENDC
			return "Error"
	for line in proc.stdout:
		result = line.rstrip()
		result = result.replace(".","")
		result = result.replace(Attribute+":","")
		return result
	
###############################################################################################################
       
def NodeDescription(Lid_based,Address,Attribute):
      
	if Lid_based == True:
		cmd =smpquery_nd_lid + str(Address) + " "  #+ " |  sed 's/\Node Description://g' | sed 's/\.\.//g' " 
	else:
		cmd =smpquery_nd_Guid +" "+ str(Address) + " " # + " | sed 's/\Node Description://g' | sed 's/\.\.//g' "
        # Put stderr and stdout into pipes
	try:
		proc = subprocess.Popen(cmd,shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE)
		return_code = proc.wait()
        # Read from pipes
	except:
		print "Something went wrong while trying to get the Port Info"
		for line in proc.stderr:
			print bcolors.FAIL + line.rstrip() + bcolors.ENDC
		return "Error"
	for line in proc.stdout:
	    result = line.rstrip()
            result = result.split(':')[1]
	    flag = True
	    while flag:
		if result.find(".") == 0:
			result = result.replace(".","",1)
		else:
			flag = False
	    
	    #result = result.replace(Attribute+":","")
            return result  

###############################################################################################################

def flint(device,Action,mstDevice=None):
	#check if mst device
	Attribute = 'PSID|FW Version'
	
	if mstDevice != None:
		flintSyntax="flint -d "
		device = mstDevice
	else:
		flintSyntax= flint_lid
	cmd = flintSyntax + str(device) + " " + Action  + " | egrep  " + "'" + Attribute + "'"
        # Put stderr and stdout into pipes
	try:
		proc = subprocess.Popen(cmd,shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE)
		return_code = proc.wait()
			
        # Read from pipes
	except:
		print "Something went wrong while trying to get the FW info"
		if proc.stderr !=None:
			for line in proc.stderr:
				print bcolors.FAIL + line.rstrip() + bcolors.ENDC
			return "Error"
	for line in proc.stdout:
		result = line.rstrip()
		att = result.split(':',2)[0]
		value = result.split(':',2)[1]
		value = value.replace(" ","")
		switchQuery[att]= value
	return True

####################################################################################	
def IsUnmanaged_1U(Lid):
	global SW_PSID
	global DevId
	global DevId_SX
	global DevId_SwitchIB
	global DevId_IS4
	DevId = NodeInfo(True,Lid,"DevId")
	
	#print SW_PSID
	if SW_PSID == "Error" :
		return "Error"
	elif DevId == DevId_SX : 
	#	for PSID in SX_PSID_Unmanaged:
		if switchQuery['PSID'] in SwitchX_PSID.keys():
			return True
			#if PSID == SW_PSID:
	
	elif DevId == DevId_SwitchIB : 
	#	for PSID in SwitchIB__PSID_Unmanaged:
		if switchQuery['PSID'] in SwitchIB_PSID.keys():
			
			return True
			#if PSID == SW_PSID:
	
	elif DevId == DevId_IS4:
	#for PSID in IS4_PSID_Unmanaged:
		if switchQuery['PSID']in IS4_PSID.keys():
			return True
			#if PSID == SW_PSID:		
	return False

####################################################################################

def getFwPSID(Lid,mstDevice=None):
	flint (Lid,"q",mstDevice)
def checkFWversion(Lid,mstDevice=None):		
	
	if switchQuery['FW Version'] in SwitchX.keys():
		return True
	
	if switchQuery['FW Version'] in SwitchIB.keys():
		return True
	
	return False
###############################################################################################################
def split_len(seq, length):
    return [seq[i:i+length] for i in range(0, len(seq), length)]

####################################################################################
def toHex(s):
    lst = []
    for ch in s:
        hv = hex(ord(ch)).replace('0x', '')
        if len(hv) == 1:
            hv = '0'+hv
        lst.append(hv)
    
    return reduce(lambda x,y:x+y, lst)

#####################################################################################

def cr_access(device,address,bit_size,data,mstDevice=None):
        
		# by default device should receive a LID value, if mstDevice is not empty, device will change to value of mstDevice
		# write cr space of Lid "Lid" in address ,offest included in the address and bit size "bit_size"
	 	
	if mstDevice != None:
		crAccessSyntax = cr_access_mst
		device = mstDevice
	else:
		crAccessSyntax = cr_access_lid
	
	
	cmd =crAccessSyntax + str(device)+ " " + address +":"+bit_size + ' ' + data
	# Put stderr and stdout into pipes
	try:
		proc = subprocess.Popen(cmd,shell=True, stderr=subprocess.PIPE, stdout=subprocess.PIPE)
		return_code = proc.wait()
	# Read from pipes
	except:
			print "Something went wrong while trying to write the new node description"

###############################################################################################################
def empty_node_desc(Lid,Asic_Type,mstDevice=None):
	if Asic_Type == DevId_SX:
		# for dword in SX_node_description:
		for dword in SwitchX[switchQuery['FW Version']]:
				cr_access(Lid,dword,"32","0x0",mstDevice)			
	if Asic_Type == DevId_SwitchIB:
		# for dword in SwitchIB _node_description:
		for dword in SwitchIB[switchQuery['FW Version']]:
				cr_access(Lid,dword,"32","0x0",mstDevice)			
	
	else:
		i=0
		if Asic_Type == DevId_IS4:
			for dword in IS4_node_description: 
				cr_access(Lid,dword,"32","0x0",mstDevice)
			
###############################################################################################################

def nameAndPadding(Name):
	i=0
	newName = Name
	paddingCounter =(len(Name.rstrip()) % 4)
	if paddingCounter > 0:
		paddingCounter = 4 - paddingCounter
	while paddingCounter > 0:
		newName= newName + padding
		paddingCounter -=1
	return newName
	

def SX_Node_Description (Lid,Name,mstDevice=None):
	
	Name_Array = split_len ( nameAndPadding(Name),4)
	i=0
	for dword in Name_Array:
		cr_access(Lid,SwitchX[switchQuery['FW Version']][i],"32","0x"+ toHex(dword),mstDevice)
		i+=1
		time.sleep(0.2)

def SwitchIB_Node_Description (Lid,Name,mstDevice=None):
	
	Name_Array = split_len ( nameAndPadding(Name),4)
	i=0
	for dword in Name_Array:
		cr_access(Lid,SwitchIB[switchQuery['FW Version']][i],"32","0x"+ toHex(dword),mstDevice)
		i+=1
		time.sleep(0.2)

		
		
###############################################################################################################
def IS4_Node_Description (Lid,Name,mstDevice=None):
	
	Name_Array = split_len (nameAndPadding(Name),4)
	i=0
	for dword in Name_Array:
		cr_access(Lid,IS4_node_description[i],"32","0x"+ toHex(dword),mstDevice)
		i+=1
		time.sleep(0.3)



###############################################################################################################
def Change_Node_Desc(Lid,Name,mstDevice=None):
	
	global DevId
	global DevId_SX
	global DevId_IS4
	global DevId_SwitchIB
	
	
	if ( DevId == DevId_SwitchIB) and (checkFWversion(Lid,mstDevice)== True):
		empty_node_desc(Lid,DevId_SwitchIB,mstDevice)
		SwitchIB_Node_Description (Lid,Name,mstDevice)
	if ( DevId == DevId_SX) and (checkFWversion(Lid,mstDevice)==True):
		empty_node_desc(Lid,DevId_SX,mstDevice)
		SX_Node_Description (Lid,Name,mstDevice)
	if DevId == DevId_IS4:
		empty_node_desc(Lid,DevId_IS4,mstDevice)
		IS4_Node_Description (Lid,Name,mstDevice)
	if ( DevId == DevId_SX) and (checkFWversion(Lid,mstDevice)==False):
		print  bcolors.FAIL + "Can't change name to SwitchX, Script can only work with FW version "  
		for fw in SwitchX.keys():
			print fw
		print bcolors.ENDC
	if ( DevId == DevId_SwitchIB) and (checkFWversion(Lid,mstDevice)==False):
		print  bcolors.FAIL + "Can't change name to SwitchIB, Script can only work with FW version "  
		for fw in SwitchIB.keys():
			print fw
		print bcolors.ENDC

###############################################################################################################
def cutit(s,n):    
   return s[n:]

###############################################################################################################
def check_if_file_exists( File ):
	try:

		if os.path.isfile(File)  == True:
			return True
		else:
			return False
	except:
		print "Couldn't verify if file " + File + "exists, exiting..."
		sys.exit()

###############################################################################################################
def Open_file( File, Method):
	global File_Mapping
	try:
		File_Mapping = open(File, Method)
		return True
	except:
		print "Couldn't open file: " + File
		File.close()
		sys.exit()

###############################################################################################################
def Name_OK(Name,length):
	if len(Name) <= length:
		return True
	else:
		return False
###############################################################################################################

def parse_lid_guid(mst_dev):

	global mstDevLid
	global mstDevCa
	global mstDevPort
	global CA
	global Port
	
	
	lidCaPort = mst_dev.split('lid-',3)[1]
	
	# parsing CA and port if exists
	mstDevLid=lidCaPort.split(',',3)[0]	
	try:
		mstDevCa = lidCaPort.split(',',3)[1]
		CA = mstDevCa
	except IndexError:
		pass
	if mstDevCa != None: 
		
		try:
			mstDevPort = lidCaPort.split(',',3)[2]
			Port = mstDevPort
		except IndexError:
			pass
	Command_syntax()
	

def Main_Switch_Flow(Lid,Guid,Name,mstDevice=None,sequence=1):
	
	global SW_PSID
	global DevId
	global DevId_SX
	global DevId_IS4
	global switchQuery
	
	switchQuery['GUID'] = Guid
	switchQuery['LID'] = Lid
	#if os.path.isfile(mstDevice):
	switchQuery['MST Device'] = mstDevice
	#else
	#	switchQuery['MST Device'] = None
	if Name_OK(Name,64) == False:
		print bcolors.FAIL + Name + " is too long , Node_Description can only be up to 64 characters" + bcolors.ENDC
	else:
		switchQuery['Type']=NodeInfo(True,Lid,"NodeType")
		if switchQuery['Type'] == "Switch":		
			switchQuery['Vendor']=NodeInfo(True,Lid,"VendorId")
			getFwPSID(Lid,mstDevice)
			if ( switchQuery['Vendor'] == VendorId_Mellanox):
				Enhanced=SwitchInfo(True,Lid,"EnhancedPort0")
				Unmanaged_1U = IsUnmanaged_1U(Lid)
				if Enhanced == "0" :
					switchQuery['OPN'] = "NA"
					if switchQuery['PSID'] in SwitchX_PSID.keys(): switchQuery['OPN'] = SwitchX_PSID[switchQuery['PSID']]
					else:
						if switchQuery['PSID'] in IS4_PSID.keys():  switchQuery['OPN']= IS4_PSID[switchQuery['PSID']]
						else:
							if switchQuery['PSID'] in SwitchIB_PSID.keys():  switchQuery['OPN']= SwitchIB_PSID[switchQuery['PSID']]
					print (str(sequence) + ". Switch Details:")
					for key in sorted(switchQuery.keys() ):
						print ("\t"+key + ": " + str( switchQuery[key] ) )
					switchQuery['Node Description'] = NodeDescription(True,switchQuery['LID'],"Node Description")
					if Unmanaged_1U == True:
						print ("\tOld Node Description: \"" + switchQuery['Node Description'] + '"')
						print ("\tRequested Node Description: \"" + bcolors.OKBLUE + nameAndPadding(Name)  + bcolors.ENDC + '"' )	
						Change_Node_Desc(Lid,Name,mstDevice)
						switchQuery['Node Description'] =  NodeDescription(True,switchQuery['LID'],"Node Description")
						print ("\tNew Node Description: \"" +bcolors.OKGREEN + switchQuery['Node Description'] + '"' +  bcolors.ENDC)		
					else:
						print (bcolors.WARNING + "\tSwitch " + switchQuery['GUID'] + " PSID is new or not in Database \n\tCheck the help menu to see supported switch PSID's" + bcolors.ENDC )
				else:
					print (bcolors.WARNING + "Switch " + switchQuery['GUID']+ " is not an unmanaged switch"  + bcolors.ENDC )
			else:
				print (bcolors.FAIL + "Switch " +Guid +" is not a Mellanox Technologies switch ,ignoring" + bcolors.ENDC )
				if (SW_PSID != "Error"):
					print ("Switch PSID: " + SW_PSID)
		else:
			if switchQuery['Type'] == "Error":
				print (bcolors.FAIL + "Can't get Node Info, is the switch reachable via InfiniBand?" + bcolors.ENDC)
			else: 
				print switchQuery['Type']
				switchQuery['Node Description'] = NodeDescription(True,Lid,"Node Description")
				print (bcolors.FAIL +"GUID: " +  str(switchQuery['GUID']) +"; Lid: "+ str(switchQuery['LID']) + "; Node Description: "+ str(switchQuery['Node Description']) +" is not a switch. " + bcolors.ENDC)
###############################################################################################################
					
def main():
	#########################################################################
	### Command line Argument filtering
	#########################################################################
	
	parser = OptionParser(usage="%prog for Usage options run the tool with -h   ", version="%prog 2.7")
	parser.add_option("-f","--file", action="store", type="string", dest="filename",
			  help="File containing Guid / MST devices to Node Description Mapping\n" + "Cannot coincide with --LID and --name\n" 
			  " The file structure:  <Guid| MST device > <Name> per line" +
			  " - No need for double quotation marks" + " wrapping the Node Description." +
			  " Create mst devices with "+ '"' + "mst ib add [local_hca_id local_hca_port]" + '"'  )
	parser.add_option("-l","--LID", action="store" ,type="int" , dest="LID",default=None,
			  help="Single Switch LID to change node description to, may not work properly if more then 1 IB port is active on the server")
			  
	parser.add_option("-g","--GUID", action="store" ,type="string" , dest="GUID",default=None,
			  help="Single Switch GUID to change node description to, may not work properly if more then 1 IB port is active on the server")
			  
	parser.add_option("-d","--mst_device", action="store" ,type="string" , dest="mstDev",default=None,
			  help="Single mst device to change node description to")
			  
	parser.add_option("-n","--name", action="store", type="string", dest="New_ND",default=None,
			  help="Node description to apply to a single switch ")
			  
	parser.add_option("-p","--padding", action="store", type="string", dest="padding",default=defaultPadding,
			  help="Padding to apply to SwitchX Node Description ")
			  
	parser.add_option("--show_psid", action="store_true", dest="showPSID",default=False,
			  help="Show supported switch PSID's  ")
			  
	parser.add_option("--show_fw", action="store_true", dest="showFW",default=False,
			  help="Show supported switch FW levels  ")		  
			  
	parser.add_option("-C","--Ca", action="store", type="string", dest="CA", default="mlx4_0",
			  help="Ca name to use, default = mlx4_0, In case of multiple active HCA's, LID or GUID may not work, use MST device instead")
			  
	parser.add_option("-P","--Port", action="store", type="string", dest="Port", default="1",
			  help="Port number to use, default = 1, In case of multiple active ports, LID or GUID may not work, use MST device instead")
	
	(options,args) = parser.parse_args()
		
	global CA
	CA = str(options.CA)
	global Port
	Port= str(options.Port)
	global padding
	padding = str(options.padding)
	
	
	Command_syntax()
	
	
	global SwithcX_PSID
	global IS4_PSID
	global mstDev
	global mstDevLid
	global mstDevCa
	global mstDevPort
	
	################## Printing FW levels and exiting #######################
	#########################################################################
	
	if (options.showFW):
		print "\nInfiniscale IV supported FW = all"
		print "SwitchX supported FW levels: "
		for fwVer in sorted(SwitchX.keys() ):
			print fwVer
		print "\n"
		print "SwitchIB supported FW levels: "
		for fwVer in sorted(SwitchIB.keys() ):
			print fwVer
		print "\n"
		exit()
	################## Printing PSID / Devices and exiting ##################
	#########################################################################
	
	if (options.showPSID):
		print "\nSwitchIB support PSIDs:\n"
		for psid, opn in sorted(SwitchIB_PSID.iteritems()):
			print psid + "  " + opn
		print "\nSwitchX Supported PSIDs / OPNs: \n"
		for psid, opn in sorted(SwitchX_PSID.iteritems()):
			print psid + "  " + opn
		print "\nInfiniscale-IV Supported PSIDs / OPNs: \n"
		for psid, opn in sorted(IS4_PSID.iteritems()):
			print psid + "  " + opn
 		print "\n"
		exit()
	
	################### File Option ##########################################
	#########################################################################
	if (options.filename != None):
		#print "Only File name provided, going to parse file, checking that lid and name wasn't provided"
		if (options.LID == None) and (options.New_ND == None) and (options.GUID == None) and ( options.mstDev == None):
			print "\nGoing to Apply new Node Description according to file "+ options.filename
			if check_if_file_exists(options.filename)==True:
				if Open_file (options.filename,'r+') == True:
				##########File opened and were good to go#############
					File_Mapping.seek(0,0)
					counter=1
					for line in File_Mapping:
						print 80*"*"
						dev=line.split(' ')[0]
						# check if mst device
						if os.path.isfile(dev):
							print dev
							print "=============="

							parse_lid_guid(dev)
							guid=NodeInfo(True,mstDevLid,"Guid")
							Lid = mstDevLid 
							New_ND = line.split(' ',1)[1]	
							New_ND = New_ND.rstrip()
							Main_Switch_Flow(Lid,guid,New_ND,dev,counter)
						else:
							print line
							New_ND = line.split(' ',1)[1]	
							New_ND = New_ND.rstrip()
							########Sending to main switch flow function############
							guid=dev
							Lid = PortInfo(False,guid,"0","Lid")
							if Lid != "Error":
								Main_Switch_Flow(Lid,guid,New_ND,None,counter)
							else:
								print bcolors.FAIL + "Couldn't resolve Guid "+ guid + " to Lid" + bcolors.ENDC
						counter += 1
					File_Mapping.close()	
			#Change_by_file(options.filename)
			else:
			     print "File " + options.filename + " doesn't exist"
			     sys.exit()
		else:
			print "File can't be specified along with Lid/Guid/Name"
			exit()
			
			
	
	################### Lid Option ##########################################
	#########################################################################
	
	elif options.LID != None:	
		if options.New_ND != None: 
		
			Main_Switch_Flow(str(options.LID),NodeInfo(True,str(options.LID),"Guid"),options.New_ND)
			
		else:
			print "Name is missing"
			exit(1)
	################### Guid Option ##########################################
	#########################################################################
	elif options.GUID != None:
		if options.New_ND != None:
			Guid = options.GUID
			Lid = PortInfo(False,Guid,"0","Lid")
			if Lid != "Error":
				Main_Switch_Flow(Lid, Guid, options.New_ND)
			else:
				print bcolors.FAIL + "Couldn't resolve Guid " + Guid + " to LID" + bcolors.ENDC
				sys.exit()
		else:
			print ("Name is missing")
			exit()
	#################### MST device #########################################
    #########################################################################

	elif options.mstDev != None:
		mstDev= options.mstDev
		 #check if mst_dev is valid
		if os.path.isfile(mstDev):
			parse_lid_guid(mstDev)
			if options.New_ND != None: 
					guid=NodeInfo(True,mstDevLid,"Guid")
					Main_Switch_Flow(mstDevLid, guid,options.New_ND,mstDev)
			else:
				print ("Name is missing, exiting")
				exit()
		else:
			print (mstDev + " is not a valid/active mst device")
			exit()	
	else: 
		print ("Usage:\n\t" \
				+ __file__ + " { -f <file> | -d <MST Device> [-n <name>] | -l <LID> [-n <name>] | -g <GUID> [-n <name>]}\n\n" \
				"Type " + __file__ + " --help for detailed help ")
	# exit()
	############
	#Cleaning
	#parser.destroy()
	
	print (bcolors.ENDC)

if __name__ == "__main__":
   main()
