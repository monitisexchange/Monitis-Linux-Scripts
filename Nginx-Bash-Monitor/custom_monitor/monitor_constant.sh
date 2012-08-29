#!/bin/bash

# Declaration of monitor constants
declare -r SERVER_HOST="10.37.125.65:80"				# host address of reverse-proxy (REPLACE it by yours)
declare -r DEST_HOST_1="195.12.12.1:80"					# target host 1 (REPLACE it by yours)
declare -r DEST_HOST_2="12.13.11.12:80"					# target host 2 (REPLACE it by yours)

declare -r SERVER_NAME="Nginx"
declare -r MONITOR_NAME=$SERVER_NAME"RP-"$SERVER_HOST 	# name of custom monitor
declare -r MONITOR_TAG="nginx"							# tag for custom monitor
declare -r MONITOR_TYPE="BASH_Monitor"					# type for custom monitor

declare -r RESULT_PARAMS="status:status::3;in_load:in_load:reqps:4;o1_load:out1_load:reqps:4;o2_load:out2_load:reqps:4;o1_perc:out1_reqs:perc:4;o2_perc:out2_reqs:perc:4;ok1:out1_2XX:perc:4;ok2:out2_2XX:perc:4" # format of result params - name1:displayName1:uom1:Integer
declare -r ADDITIONAL_PARAMS="details:info::3"	# format of additional params - name:displayName:uom:String

declare -r DUMMY_RESULT="status:IDLE;in_load:0;o1_load:0;o2_load:0;o1_perc:0;o2_perc:0;ok1:0;ok2:0 | details + No input request to Nginx."
declare -r DEAD_RESULT="status:DEAD | details + Nginx process not found"
declare -r OK_STATUS="status:OK"

declare -r LOG_FILE=~/monitor.log				# Monitored server (Nginx) textual log file path (REPLACE by your file path)
declare -r RES_FILE=~/tmp.txt				    # temporary file

# declaration of pattern-strings for finding in log file
# The string of any number of extended patterns can be defined in conform to format of "Linux grep tool"
declare -ra dir=("$DEST_HOST_1" "$DEST_HOST_2")	# interesting IPs 
declare -r ok="^[2][0-9]{1,2}$"					# Pattern to grab 2xx (success) codes

declare -r tot="total"
declare -r successful="successful"

declare -r c1xx="1xx"
declare -r c2xx="2xx"
declare -r c3xx="3xx"
declare -r c4xx="4xx"
declare -r c5xx="5xx"
	
declare    DURATION=5	 							# information sending duration [min] (REPLACE by any desired value)
