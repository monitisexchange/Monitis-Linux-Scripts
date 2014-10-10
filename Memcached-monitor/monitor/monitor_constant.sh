#!/bin/bash

# Declaration of monitor constants
declare    HOST_IP="HOST_IP"							# host mashine real IP-address
declare    MEMCACHED_IP=127.0.0.1						# host IP where located remote MySQL master
declare    MEMCACHED_PORT=11211							# remote MySQL master listen port

declare -r NAME="Memcached"
declare    MONITOR_NAME="$NAME"_"$HOST_IP:$MEMCACHED_PORT" # name of custom monitor
declare -r MONITOR_TAG="memcached"						# tag for custom monitor
declare -r MONITOR_TYPE="BASH_Monitor"					# type for custom monitor
# monitor commands
declare -r MON_PATHNAME="node_monitor"
declare -r MON_ACTION="action"
declare -r MON_GET_DATA="getData"
declare -r MON_GET_ADATA="getAData"

# format of result params - name1:displayName1:uom1:Integer
declare -r P1="status:status::3;uptime:uptime::3"
declare -r P2="get_miss:get_miss:perc:4;delete_miss:delete_miss:perc:4;incr_miss:incr_miss:perc:4;decr_miss:decr_miss:perc:4;evictions:evictions:perc:4"
declare -r P3="in_kbps:in_kbps::4;out_kbps:out_kbps::4;reqs:reqs:rps:4;conn:conns:perc:4;mem_usage:mem_usage:perc:4"
declare -r RESULT_PARAMS="$P1;$P2;$P3"

# format of additional params - name:displayName:uom:String
declare -r ADDITIONAL_PARAMS="details:Details::3"

declare -r NORM_STATE="OK"
declare -r IDLE_STATE="IDLE"
declare -r FAIL_STATE="NOK"
declare -r UNAC_STATE="status:DOWN"

declare -r CMD_SETTING="stats settings"
declare    FILE_SETTING="setting"
declare -r CMD_STATUS="stats"
declare    FILE_STATUS="status"
declare    FILE_STATUS_PREV="status_"

declare    DURATION=5	 				# information sending duration [min] (REPLACE by any desired value)

declare    return_value			# working parameter
