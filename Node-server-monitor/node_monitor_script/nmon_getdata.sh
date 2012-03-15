#!/bin/bash

# sorces included
source monitis_api.sh  || exit 2
source monitor_constant.sh  ||  error 2 monitor_constant.sh

declare -i days=1
declare    path="."

#read argument; in this case the monitoring folders paths
while getopts "d:p:h" opt;
do
        case $opt in
        d) days=$OPTARG ;;
        p) path=$OPTARG ;;
        h) echo "Usage: $0 -d <number of days to get data for> -p <directory path to storing data-files> "; exit 0 ;;
        *) error 4 "Wrong parameter received" ;;
        esac
done

echo "*** Node.js server motoring data for $days days will be grabbed and stored in the $path directory ***"

# obtaining TOKEN
get_token
ret="$?"
if [[ ($ret -ne 0) ]]
then
	error 3 "$MSG"
else
	echo RECEIVE TOKEN: "$TOKEN" at `date -u -d @$(( $TOKEN_OBTAIN_TIME/1000 ))`
	#echo "All is OK for now."
fi

MONITOR_ID=`get_monitorID $MONITOR_NAME $MONITOR_TAG $MONITOR_TYPE `
ret="$?"
if [[ ($ret -ne 0) ]]
then
	error "$ret" "$MSG"
else
	echo Custom monitor id = "$MONITOR_ID"
	#echo "All is OK for now."
fi

file=$path"/node_data"
timestamp=`date -u +%s`

for ((i=0; i<$days; i++ ))
do
	d=`date -d @$timestamp +"%F" `
	get_custom_monitor_data "$d"
	res="$?"
	if [[ ($res -ne 0) ]]
	then
		error "$ret" "$MSG"
	else
		isJSONarray "$response"
		ret="$?"
		if [[ ($ret -ne 0) ]]
 		then
 			error 1 "The response isn't JSON array - skip it"
 		elif [[ (${#response} -le 3) ]]
 		then
 			error 1 "The response contains no data - skip it"
 		else
 			echo "***writing data for $d ***"
			echo $response | sed 's/},{/\n/g' | sed 's/\[{//g' | sed 's/}\]//g' > $file"_"$d
		fi
	fi
	timestamp=$(( $timestamp - (24*60*60) )) # calculates a previous day timestamp
done

