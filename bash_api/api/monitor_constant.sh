#!/bin/bash

# Custom parameters
declare    RANGE=1000
declare    THRESHOLD=600

# Declaration of monitor constants
declare -r NAME="Monitor"
declare    MONITOR_NAME="$NAME"_"$RANGE" # name of custom monitor
declare -r MONITOR_TAG="BASH_Monitor"	 # tag for custom monitor
declare -r MONITOR_TYPE="Custom"	     # type for custom monitor

# format of result params - name:displayName:uom:type
declare -r RESULT_PARAMS="status:status::3;test:test::2" 

# format of additional params - name:displayName:uom:String
declare -r ADDITIONAL_PARAMS="details:Details::3"	
	
declare    DURATION=5	 		# information sending duration [min] (REPLACE by any desired value)

declare    return_value			# working parameter
