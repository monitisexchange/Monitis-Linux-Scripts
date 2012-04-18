#!/bin/bash
# set -x
# sources included
source monitis_api.sh   || exit 2
source monitis_constant.sh || exit 2
source riak_monitor.sh  || exit 2

ADDITIONAL_PARAMS=""
MONITOR_NAME="Riak_Monitor"_`hostname`
MONITOR_TAG="riak"
MONITOR_TYPE="customMonitor"
#
echo "***Riak Monitor start with following parameters***"
echo "Monitor name = $MONITOR_NAME"


# obtaining TOKEN
get_token
ret="$?"
if [[ ($ret -ne 0) ]]
then
	error 3 "$MSG"
else
	echo RECEIVE TOKEN: "$TOKEN" at `date -u -d @$(( $TOKEN_OBTAIN_TIME/1000 ))`
	echo "All is OK for now."
fi
#
get_data
RESULT_PARAMS="$result"
#
if [[ $1 == "create" ]];then
	# Adding custom monitor
	add_custom_monitor "$MONITOR_NAME" "$MONITOR_TAG" "$RESULT_PARAMS" "$ADDITIONAL_PARAMS" "$MONITOR_TYPE"
ret="$?"
if [[ ($ret -ne 0) ]]
then
	error "$ret" "$MSG"
else
	echo Custom monitor id = "$MONITOR_ID"
	echo "$MONITOR_ID" > .monitor.id
	echo "All is OK for now."
	fi
fi

if [[ ($MONITOR_ID -le 0) ]]
then 
	echo MonitorId is still zero - try to obtain it from local cache
	
	MONITOR_ID=`cat .monitor.id`
	ret="$?"
	if [[ ($ret -ne 0) ]]
	then
		error "Could not get monitor id from local cache [.monitor.id]"
	else
		echo Custom monitor id = "$MONITOR_ID"
		echo "All is OK for now."
	fi
fi

	get_token				# get new token in case of the existing one is too old
	ret="$1"
	if [[ ($ret -ne 0) ]]
	then	# some problems while getting token...
		error "$ret" "$MSG"
		exit 1
	fi
	ret="$1"
	if [[ ($ret -ne 0) ]];then
	    error "$ret" "$MSG"
	    exit 1
	fi

	# Compose monitor data
	get_data
	param=$postdata
	timestamp=`get_timestamp`
	# Sending to Monitis
	add_custom_monitor_data $param $timestamp
	ret="$?"
	if [[ ($ret -ne 0) ]];then
		error "$ret" "$MSG"
		exit 1
	else
		echo $( date +"%D %T" ) - The Custom monitor data were successfully added
	fi





