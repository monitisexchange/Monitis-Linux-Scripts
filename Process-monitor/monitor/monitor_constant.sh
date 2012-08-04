#!/bin/bash

# Declaration of monitor constants
declare    PROC_CMD=memcached
declare -i PROC_ID=929

declare    MONITOR_NAME="Process_$PROC_CMD"			# name of custom monitor
declare -r MONITOR_TAG="Process"					# tag for custom monitor
declare -r MONITOR_TYPE="BASH_Monitor"				# type for custom monitor

# format of result params - name1:displayName1:uom1:Integer
declare -r RESULT_PARAMS="status:status::3;cpu:cpu:pr:4;mem:mem:pr:4;virt:virt:mb:2;res:res:mb:2;ofd:ofd::2;osd:osd::2;ofd_pr:ofd_pr::4;threads:threads::2;uptime:uptime::3" 

declare -r RESP_DOWN="status:DOWN"
	
# format of additional params - name:displayName:uom:String
declare -r ADDITIONAL_PARAMS="details:Details::3"	
	
declare    DURATION=1	 							# information sending duration [min] (REPLACE by any desired value)
