#!/bin/bash

# Declaration of monitor constants
# The host mashine real IP-address
declare    HOST_IP="10.137.25.64"
# Declaration of RabbitMQ access point and credentials
declare -r HOST="127.0.0.1"
declare -r PORT=15672
declare -r USER="guest"
declare -r PSWD="guest"
# Declaration of Monitor name
declare -r NAME="Test_RabbitMQ"
declare    MONITOR_NAME="$NAME"_"$HOST_IP:$PORT" 	# name of custom monitor
declare -r MONITOR_TAG="rabbitmq"					# tag for custom monitor
declare -r MONITOR_TYPE="BASH_Monitor"				# type for custom monitor
declare -r MULTIVALUE="true"

# monitor commands
declare -r MON_ACTION="action"
declare -r MON_GET_DATA="getData"
declare -r MON_GET_ADATA="getAData"

# format of result params - name1:displayName1:uom1:Integer (1 - boolean, 2 - integer, 3 - string, 4 - float)
declare -r P1="name:name::3:true;state:state::3;consumers:consumers::2;memory:memory:mb:4"
declare -r P2="msg_ready:msg_ready::2;msg_unack:msg_unack::2;msg_total:msg_total::2"
declare -r P3="rate_in:rate_in:rps:4;rate_get:rate_get:rps:4;rate_ack:rate_ack:rps:4"
declare -r RESULT_PARAMS="$P1;$P2;$P3"

# format of additional params - name:displayName:uom:String
declare -r ADDITIONAL_PARAMS="details:Details::3"

declare -r NORM_STATE="OK"
declare -r IDLE_STATE="IDLE"
declare -r FAIL_STATE="FAIL"
declare -r UNAC_STATE="status:FAIL | details + Cannot access to the rabbitmq engine"

declare    DURATION=5

declare    return_value			# working parameter
