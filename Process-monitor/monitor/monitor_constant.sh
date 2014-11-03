#!/bin/bash

# Declaration of monitor constants
declare    HOST="host address"					# replace by your host ip
declare    PROC_CMD='unique command/regex'		# replace by your process command
declare    PROC_ID=0							# replace by your process PID (optional)

declare -r NAME="Process"
declare    MONITOR_NAME="$NAME"_"$HOST"_"$PROC_CMD"		# name of custom monitor
declare -r MONITOR_TAG="Process"				# tag for custom monitor
declare -r MONITOR_TYPE="BASH_Monitor"			# type for custom monitor
declare -r MULTIVALUE="true"

# format of result params - name1:displayName1:uom1:Integer
declare -r RESULT_PARAMS="status:status::3;pid:pid::2:true;cpu:cpu:pr:4;mem:mem:pr:4;res:res:mb:2;ofd:ofd::2;osd:osd::2;ofd_pr:ofd_pr::4;threads:threads::2;uptime:uptime::3" 

declare -r RESP_DOWN="status:DOWN"

# format of additional params - name:displayName:uom:String
declare -r ADDITIONAL_PARAMS="details:Details::3"

declare    DURATION=5	 		# information sending duration [min] (REPLACE by any desired value)

declare    return_value			# working parameter
