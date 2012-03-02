#!/bin/bash

# Declaration of monitor constants
declare -r SERVER_HOST="10.37.125.65:80"				# host address of reverse-proxy (REPLACE it by yours)
declare -r DEST_HOST_1="195.12.12.1:80"					# target host 1 (REPLACE it by yours)
declare -r DEST_HOST_2="12.13.11.12:80"					# target host 2 (REPLACE it by yours)

declare -r MONITOR_NAME="nginx_monitor_$SERVER_HOST"	# name of custom monitor
declare -r MONITOR_TAG="nginx"							# tag for custom monitor
declare -r MONITOR_TYPE="BASH_Monitor"					# type for custom monitor


declare -r RESULT_PARAMS="in:in_load:reqps:4;out1:dest1_load:reqps:4;out2:dest2_load:reqps:4;ok1:out1_2XX:perc:4;ok2:out2_2XX:perc:4" # format of result params - name1:displayName1:uom1:Integer
declare -r ADDITIONAL_PARAMS="details:info::3"	# format of additional params - name:displayName:uom:String

declare -r LOG_FILE=~/log/monitor.log				# Monitored server (Nginx) textual log file path (REPLACE by your file path)
declare -r RES_FILE=~/log/tmp.txt				# temporary file

# declaration of pattern-strings for finding in log file
# The string of any number of extended patterns can be defined in conform to format of "Linux grep tool"
declare -ra dir=("$DEST_HOST_1" "$DEST_HOST_2")	# interesting IPs 
declare -r ok="^[2][0-9]{1,2}$"					# Pattern to grab 2xx (success) codes

declare -r tot="total"
declare -r successful="successful"
	
declare    DURATION=1	 							# information sending duration [min] (REPLACE by any desired value)
