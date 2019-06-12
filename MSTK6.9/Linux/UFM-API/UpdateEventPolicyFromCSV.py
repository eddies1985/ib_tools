#!/usr/bin/python
"""
This script is intended to be used to update UFM Event Policy from an input CSV file

Author:
    eladh@mellanox.com
Date:
    14/11/2012
    
Copyright (C) Mellanox Technologies Ltd. 2001-2011.  ALL RIGHTS RESERVED.
This software product is a proprietary product of Mellanox Technologies Ltd.
(the "Company") and all right, title, and interest in and to the software product,
including all associated intellectual property rights, are and shall
remain exclusively with the Company.

This software product is governed by the End User License Agreement
provided with the software product.


Activation Example:
    python UpdateEventPolicyFromCsv.py -f eggs.csv


"""

#Imports
import csv
import sys
import os
import getopt
from ufmsdk import infratools
from ufmsdk import ufmapi

#Class Variables
server = None  # Null for localhost
ufm_api = None
user = 'admin'
password = '123456'
pathToFile = "/opt/ufm/scripts/custom_policy.csv"
version = 1.0
policyList = None
changedObjectsList = []
scriptName = os.path.basename(sys.argv[0])
sys.path.append(os.path.dirname(sys.path[0]))
logger = infratools.initLogger(scriptName, 1, True, scriptName + ".log", False)

#Usage
def Usage():
        print
        print "Usage: %s [-s UFM REMOTE SERVER] [-u USER] [-p PASSWORD] [-v] [-h]"  % os.path.basename(sys.argv[0])
        print
        print "Options:"
        print "     [-s UFM REMOTE SERVER]     - Connect to remote UFM server"
        print "     [-u USER]                  - User to connect to UFM server"
        print "     [-p PASSWORD]              - Password to connect to UFM server"
        print "     [-f CSV FILE]              - Path to input CSV file"
        print "     [-v]                       - Show version "
        print "     [-h]                       - Show this help "
        print
        sys.exit(1)

#Check Arguments
try:
        opts, args = getopt.getopt(sys.argv[1:], "s:u:p:f:hv", ["version"])

except getopt.error :
        raise Usage()

#Assign Arguments
for opt, arg in opts :
        if opt == '-s':
                server = arg
        elif opt == '-u':
                user = arg
        elif opt == '-p':
                password = arg
        elif opt == '-f':
                pathToFile = arg
        elif opt in ('-h', '--help'):
                Usage()
        elif opt in ('-v', '--version'):
                print os.path.basename(sys.argv[0]), "Version" , version
                sys.exit(2)
    
#Connect to UFM server
ufm_api = ufmapi.UFMAPI(user, password, server)

#Get all Event Policies from UFM Server
try:
        policyList = ufm_api.getAllEventPolicies()
except Exception, e:
        logger.error("main_function threw unhandled exception: %s" % e)
        print "Error, Main function threw unhandled exception: ", e
        

#Function to update the Policy in UFM
def update_policy(rowToUpdate):
        for policy in policyList:
                if policy.name == rowToUpdate[0]:
                        if str(policy.to_ui) != rowToUpdate[2]:
                                policy.to_ui = rowToUpdate[2]
                                changedObjectsList.append(logger.info("On policy --> " + rowToUpdate[1] + ", GUI field changed to " + rowToUpdate[2]))
                        if str(policy.use_alarm) != rowToUpdate[3]:
                                policy.use_alarm = rowToUpdate[3]
                                changedObjectsList.append(logger.info("On policy --> " + rowToUpdate[1] + ", Alarm field changed to " + rowToUpdate[3]))
                        if str(policy.to_log) != rowToUpdate[4]:
                                policy.to_log = rowToUpdate[4]
                                changedObjectsList.append(logger.info("On policy --> " + rowToUpdate[1] + ", Log field changed to " + rowToUpdate[4]))
                        if str(policy.call_script) != rowToUpdate[5]:
                                policy.call_script = rowToUpdate[5]
                                changedObjectsList.append(logger.info("On policy --> " + rowToUpdate[1] + ", Call Script field changed to " + rowToUpdate[5]))
                        if str(policy.to_snmp) != rowToUpdate[6]:
                                policy.to_snmp = rowToUpdate[6]
                                changedObjectsList.append(logger.info("On policy --> " + rowToUpdate[1] + ", SNMP field changed to " + rowToUpdate[6]))
                        if str(policy.threshold) != rowToUpdate[7]:
                                policy.threshold = rowToUpdate[7]
                                changedObjectsList.append(logger.info("On policy --> " + rowToUpdate[1] + ", Threshold field changed to " + rowToUpdate[7]))
                        if str(policy.duration) != rowToUpdate[8]:
                                policy.duration = rowToUpdate[8]
                                changedObjectsList.append(logger.info("On policy --> " + rowToUpdate[1] + ", TTL field changed to " + rowToUpdate[8]))
                        if str(policy.severity) != rowToUpdate[9]:
                                policy.severity = rowToUpdate[9]
                                changedObjectsList.append(logger.info("On policy --> " + rowToUpdate[1] + ", Severity field changed to " + rowToUpdate[9]))
                                
                        #Push the new updated policy object to UFM
                        ufm_api.updateEventPolicy(policy)
                        


#Check CSV file is valid
def is_row_valid(row):
        if row == None:
                logger.error("Row is Null, skipping...")
                print "Row is Null, skipping..."
                return False
        if (row[0] == "ID" and row[1] == "Event Name"):
                return False
        if len(row) != 10:
                logger.error("Number of fields in row is not 10")
                print "Number of fields in row is not 10"
                return False
        if (row[0] < 1 and row[0] > 1000):
                logger.error("Event policy number is invalid - " +row[0])
                print "Event policy number is invalid"
                return False
        if row[2] not in ("True", "False"):
                logger.error("Boolean fields invalid - " +row[2])
                print "Boolean fields invalid"
                return False
        if row[9] not in ("Info", "Warning", "Minor", "Critical"):
                logger.error("Severity is not Info, Warning, Minor or Critical - " +row[9])
                print "Severity is not Info, Warning, Minor or Critical"
                return False
        return True


#Main
if __name__ == '__main__':
        #CSV Handle
        #File IO is "dangerous"
        try:
                with open(pathToFile, 'rb') as csvfile:
                        spamreader = csv.reader(csvfile, delimiter=',', quotechar='|')
                        print "Using " + pathToFile + " as an input file."
                        for row in spamreader:
                                #Check row is valid
                                if is_row_valid(row):
                                        #Update the policy in UFM
                                        update_policy(row)
                        #Print number of changed values
                        print "\nDone!\nTotal of " + str(len(changedObjectsList)) + " values changed."
                                
        #Catch IOErrors, e is the instance
        except IOError, e:              
                print "Error in file IO: ", e
