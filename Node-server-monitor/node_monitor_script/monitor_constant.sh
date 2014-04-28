#!/bin/bash

# Declaration of monitor constants
declare -r MON_SERVER="test"					# monitored server host
declare -r NODE_MONITOR="http://127.0.0.1:10010/"		# node server monitor access url
declare    ACCESS_CODE="monitis"						# access code for node monitor

declare -r NAME="Node.js"
declare    MONITOR_NAME="$NAME"_"$MON_SERVER"			# name of custom monitor
declare -r MONITOR_TAG="Node_Server"				# tag for custom monitor
declare -r MONITOR_TYPE="BASH_Monitor"				# type for custom monitor
# monitor commands
declare -r MON_PATHNAME="node_monitor"
declare -r MON_ACTION="action"
declare -r MON_GET_DATA="getData"
declare -r MON_GET_ADATA="getAData"

declare -r MON_ACCESS="access_code"
declare -r DUMMY_CODE="monitis"

# format of result params - name1:displayName1:uom1:Integer
# name, displayName, uom and value should be URL encoded.
#UOM is unit of measure(user defined string parameter, e.g. ms, s, kB, MB, GB, GHz, kbit/s, ... ).
#
#dataType:   1 for boolean    2 for integer    3 for string    4 for float
#

declare -r P0="status:status::3;uptime:uptime::3"
declare -r P1="avr_resp:avr_resp:s:4;max_resp:max_resp:s:4"
declare -r P11="avr_net:avr_net:s:4;max_net:max_net:s:4"
declare -r P12="avr_total:avr_total:s:4;max_total:max_total:s:4"
declare -r P2="in_rate:in_rate:kbps:4;out_rate:out_rate:kbps:4"
declare -r P3="active:active:percent:4;load:load:reqps:4"
declare -r RESULT_PARAMS="$P0;$P1;$P11;$P12;$P2;$P3"

declare -r RESP_DOWN="status:DOWN"

# format of additional params - name:displayName:uom:String
declare -r ADDITIONAL_PARAMS="details:Details::3"

declare    DURATION=5 						# information sending duration [min] (REPLACE by any desired value)

declare    return_value			# working parameter
