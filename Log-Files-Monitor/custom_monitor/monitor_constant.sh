#!/bin/bash

declare -r LOG_FILE=~/temporary/tmp.log					# Monitored textual log file path (REPLACE by any other monitored textual file)
declare -r COUNT_FILE=~/temporary/errors.txt			# counters file

# Declaration of monitor constants
declare -r NAME="Log_monitor"
declare  MONITOR_NAME="$NAME"_$(basename "$LOG_FILE")	# name of custom monitor
declare -r MONITOR_TAG="logging"						# tag for custom monitor
declare -r MONITOR_TYPE="customMonitor"					# type for custom monitor

# monitor commands
declare -r MON_PATHNAME="node_monitor"
declare -r MON_ACTION="action"
declare -r MON_GET_DATA="getData"
declare -r MON_GET_ADATA="getAData"

declare  RESULT_PARAMS="status:status::3;event0:Line_count::2" 	# format of result params - name1:displayName1:uom1:Integer
#declare -r ADDITIONAL_PARAMS="details:Errors_detail::3"	# format of additional params - name:displayName:uom:String

declare -r DUMMY_RESULT="status:NOK"
declare -r FAIL_RESULT="status:FAIL"
declare -r OK_RESULT="status:OK"

declare -r DEBUG=true

# declaration of pattern-strings for finding in log file
# The string of any number of extended patterns can be defined in conform to format of "Linux grep tool"
declare -a PATTERNS=("error" "warning" "serious")

declare    DURATION=5 						# information sending duration [min] (REPLACE by any desired value)

declare    return_value			# working parameter
