#!/bin/bash

# Declaration of monitor constants

declare -r MONITOR_NAME="freeRadius"	# name of custom monitor
declare -r MONITOR_TAG="radius"			# tag for custom monitor
declare -r MONITOR_TYPE="BASH_Monitor"	# type for custom monitor

declare -r RESULT_PARAMS="status:status::3;reqTime:reqTime:sec:4" # format of result params - name1:displayName1:uom1:Integer

# declaration of pattern-strings for finding in log file
# The string of any number of extended patterns can be defined in conform to format of "Linux grep tool"

declare    DURATION=5	 				# information sending duration [min] (REPLACE by any desired value)
declare    OK="OK"
declare    NOK="NOK"
declare    DEAD="DEAD"
declare    TESTUSER="testuser"          #replace with the test user's username which you should have added to Radius (usually in /etc/freeradius/users)
declare    TESTPASSWORD="123456Aa"      #replace with the test user's password
declare    SECRET="testing123"          #replace with the Radius actual secret
declare    PORT=1812                    #one need to change this if she uses other port that the Radius default
declare    HOST="137.10.25.173"			#the IP of the host carrying Radius server.
