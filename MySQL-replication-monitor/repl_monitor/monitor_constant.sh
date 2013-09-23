#!/bin/bash

# Declaration of monitor constants
declare -r MASTER_HOST=<IP of host where located master DB>		# host IP where located remote MySQL master
declare -r MASTER_PORT=3306						# remote MySQL master listen port
declare -r MASTER_USER=root						# remote MySQL master root user name
declare -r MASTER_PASSWORD=<MySQL master password>			# remote MySQL master root user password

declare -r SLAVE_HOST=<IP of host where located slave DB>		# host IP where located remote MySQL slave
declare -r SLAVE_PORT=3306						# remote MySQL slave listen port
declare -r SLAVE_USER=root						# remote MySQL slave root user name
declare -r SLAVE_PASSWORD=<MySQL slave password>			# remote MySQL slave root user password

declare -r NAME="MySQL_replication"
declare -r MONITOR_NAME="$NAME_$MASTER_HOST->$SLAVE_HOST" 	# name of custom monitor
declare -r MONITOR_TAG="replication"					# tag for custom monitor
declare -r MONITOR_TYPE="BASH_Monitor"					# type for custom monitor

# format of result params - name1:displayName1:uom1:Integer
# name, displayName, uom and value should be URL encoded.
#UOM is unit of measure(user defined string parameter, e.g. ms, s, kB, MB, GB, GHz, kbit/s, ... ).
#
#dataType:   1 for boolean    2 for integer    3 for string    4 for float
#
declare -r RESULT_PARAMS="alive:Alive::3;late:Slave_late[sec]:sec:2;desynch:Desynch[pr]:pr:4;last_errno:Last_errno::2;discord:Discord[pr]::4" 

declare -r RESP_DOWN="alive:no"
	
# format of additional params - name:displayName:uom:String
declare -r ADDITIONAL_PARAMS="details:Details::3"
	
declare    DURATION=5	 		# information sending duration [min] (REPLACE by any desired value)
