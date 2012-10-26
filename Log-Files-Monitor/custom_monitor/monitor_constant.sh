#!/bin/bash

declare -r LOG_FILE=~/temporary/tmp.log					# Monitored textual log file path (REPLACE by any other monitored textual file)
declare -r ERR_FILE=~/temporary/errors.txt				# temporary file

# Declaration of monitor constants
declare -r NAME="Log_monitor"
declare -r MONITOR_NAME="$NAME"_for_"$(basename "$LOG_FILE")	# name of custom monitor
declare -r MONITOR_TAG="logging"						# tag for custom monitor
declare -r MONITOR_TYPE="BASH_Monitor"					# type for custom monitor

declare -r RESULT_PARAMS="events:Event_count::2;status:status::3" 		# format of result params - name1:displayName1:uom1:Integer
#declare -r ADDITIONAL_PARAMS="details:Errors_detail::3"	# format of additional params - name:displayName:uom:String

declare -r DUMMY_RESULT="events:0;status:NOK"
declare -r FAIL_RESULT="status:FAIL"
declare -r OK_RESULT="status:OK"

# declaration of pattern-strings for finding in log file
# The string of any number of extended patterns can be defined in conform to format of "Linux grep tool"
declare -r PATTERN="error|warning|serious"

declare    DURATION=1	 							# information sending duration [min] (REPLACE by any desired value)
