#!/bin/bash

# Declaration of monitor constants
declare -r HOST="localhost"
declare -r USER="<DB user name>"				# remote MySQL master root user name
declare -r PASSWORD="<DB user password>"			# remote MySQL master root user password

declare -r MONITOR_NAME="MySQL_$HOST" 				# name of custom monitor
declare -r MONITOR_TAG="MySQL"					# tag for custom monitor
declare -r MONITOR_TYPE="BASH_Monitor"				# type for custom monitor

# format of result params - name1:displayName1:uom1:Integer
declare -r P0="status:Status::3;receive:Received:kb:4;send:Sent:kb:4;insert:Insert::2;select:Select::2;update:Update::2;delete:Delete::2"
declare -r P1="queries:Queries::2;slow_queries:Slow_queries::2;thread_running:Threads_running::2;Connections_usage:Connections_usage:pr:4;uptime:Uptime::3"
declare -r RESULT_PARAMS="$P0;$P1" 

declare -r RESP_DOWN="status:DOWN"
	
# format of additional params - name:displayName:uom:String
declare -r ADDITIONAL_PARAMS="details:Details::3"	
	
declare    DURATION=5	 					# information sending duration [min] (REPLACE by any desired value)
