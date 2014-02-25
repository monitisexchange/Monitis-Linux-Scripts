#!/bin/bash

# Declaration of monitor constants
declare -r HOST="FTP server IP"			# monitored FTP server host
declare -r USER="user name"			# node server monitor access url
declare -r PASSWD="password"			# access code for node monitor
declare -r FOLDER="remote folder"		# remote folder

declare -r NAME="FTPmon"
declare    MONITOR_NAME="$NAME"_"$HOST"					# name of custom monitor
declare -r MONITOR_TAG="FTP"							# tag for custom monitor
declare -r MONITOR_TYPE="BASH_Monitor"					# type for custom monitor
declare -r MULTIVALUE=true
# monitor commands
declare -r MON_PATHNAME="node_monitor"
declare -r MON_ACTION="action"
declare -r MON_GET_DATA="getData"
declare -r MON_GET_ADATA="getAData"

# format of result params - name1:displayName1:uom1:Integer
# name, displayName, uom and value should be URL encoded.
#UOM is unit of measure(user defined string parameter, e.g. ms, s, kB, MB, GB, GHz, kbit/s, ... ).
#
#dataType:   1 for boolean    2 for integer    3 for string    4 for float
#
declare -r PARAMS="[action, code, size, time_total, time_connect, time_transfer, speed]"
declare -r RESULT_PARAMS="code:code::3;size:size:byte:2;time_total:time_total:s:4;time_connect:time_connect:s:4;time_transfer:time_transfer:s:4;speed:speed:bps:4;action:action::3:true"

declare -r RESP_DOWN="status:DOWN"

# format of additional params - name:displayName:uom:String
declare -r ADDITIONAL_PARAMS="details:Details::3"

declare    DURATION=5 						# information sending duration [min] (REPLACE by any desired value)

declare    return_value			# working parameter
