#!/bin/bash

# Custom parameters
declare    RANGE=1000
declare    THRESHOLD=600

# Declaration of monitor constants
declare -r NAME="Monitor"
declare    MONITOR_NAME="$NAME"_"$RANGE" # name of custom monitor
declare -r MONITOR_TAG="BASH_Monitor"	 # tag for custom monitor
declare -r MONITOR_TYPE="Custom"	     # type for custom monitor

# format of result params - name1:displayName1:uom1:Integer
# name, displayName, uom and value should be URL encoded.
#UOM is unit of measure(user defined string parameter, e.g. ms, s, kB, MB, GB, GHz, kbit/s, ... ).
#
#dataType:   1 for boolean    2 for integer    3 for string    4 for float
#

declare -r RESULT_PARAMS="status:status::3;test:test::2" 

# format of additional params - name:displayName:uom:String
declare -r ADDITIONAL_PARAMS="details:Details::3"
	
declare    DURATION=5	 		# information sending duration [min] (REPLACE by any desired value)

declare    return_value			# working parameter
