#!/bin/bash

# Declaration of monitor constants
declare    HOST_IP="127.0.0.1"						# host mashine real IP-address
declare -r HOST="127.0.0.1"
#declare -r PORT=55672					# port for RabbitMQ versions prior to 3.0 is 55672
declare -r PORT=15672					# port for RabbitMQ since version 3.0 is 15672
declare -r USER="guest"
declare -r PSWD="guest"

declare -r NAME="RabbitMQ"
declare    MONITOR_NAME="$NAME"_"$HOST_IP:$PORT" 	# name of custom monitor
declare -r MONITOR_TAG="rabbitmq"					# tag for custom monitor
declare -r MONITOR_TYPE="BASH_Monitor"				# type for custom monitor
declare -r MULTIVALUE="false"

# monitor commands
declare -r MON_ACTION="action"
declare -r MON_GET_DATA="getData"
declare -r MON_GET_ADATA="getAData"

# format of result params - name1:displayName1:uom1:Integer
declare -r P1="status:status::3;uptime:uptime::3"
declare -r P2="osd:osd_pr::4;ofd:ofd_pr::4;cpu_usage:cpu_usage::4;mem_usage:mem_usage::4;msg_queue:msg_in_queue::2;consumers:consumers::2"
declare -r P3="sent_mps:pub_rate:mps:4;recv_kbps:from_client_rate:kbps:4;sent_kbps:to_client_rate:kbps:4;recv_mps:get_rate:mps:4"
declare -r RESULT_PARAMS="$P1;$P2;$P3"

# format of additional params - name:displayName:uom:String
declare -r ADDITIONAL_PARAMS="details:Details::3"

declare -r NORM_STATE="OK"
declare -r IDLE_STATE="IDLE"
declare -r FAIL_STATE="NOK"
declare -r UNAC_STATE="status:FAIL | details + Cannot access to the rabbitmq engine"

declare    DURATION=5	 				# information sending duration [min] (REPLACE by any desired value)

declare    return_value			# working parameter
