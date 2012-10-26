#!/bin/bash

# sorces included
source monitis_api.sh	|| exit 2
source monitor_constant.sh  ||  error 2 monitor_constant.sh
source ticktick.sh		|| error 2 ticktick.sh

declare -i days=1
declare    path="."
declare    file_prefix=""

#read argument; in this case the monitoring folders paths
while getopts "d:p:m:f:h" opt;
do
        case $opt in
        d) days=$OPTARG ;;
        p) path=$OPTARG ;;
        f) file_prefix=$OPTARG ;;
        m) MONITOR_ID=$OPTARG ;;
        h) echo "Usage: $0 -d <number of days to get data for> -p <directory path to storing data-files> -f <file name prefix> -m <monitorID>" ; exit 0 ;;
        *) error 4 "Wrong parameter received" ;;
        esac
done

echo "*** Motoring data for $days days will be grabbed and stored in the $path directory with file prefix $file_prefix ***"

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

if [[ ($MONITOR_ID -eq 0) ]]
then	# retrieve monitor ID
	echo "Retrieving monitor ID for $MONITOR_NAME $MONITOR_TAG $MONITOR_TYPE..."
	MONITOR_ID=`get_monitorID "$MONITOR_NAME" "$MONITOR_TAG" "$MONITOR_TYPE" `
	ret="$?"
	if [[ ($ret -ne 0) ]]
	then
		error "$ret" "$MSG"
	else
		echo Custom monitor id = "$MONITOR_ID"
		#echo "All is OK for now."
	fi
else	# retrieve the monitor name
	echo "Getting Monitor info..."
	get_custom_monitor_info "$MONITOR_ID"
	ret="$?"
	if [[ ($ret -ne 0) ]]
	then
		error "$ret" "$MSG"
	else
		isJSON "$response"
		ret="$?"
		if [[ ($ret -ne 0) ]]
 		then
 			error 3 "The response isn't JSON while getCustomMonitorInfo\($MONITOR_ID\)"
 		elif [[ (${#response} -le 3) ]]
 		then
 			error 3 "The response contains no any data while getCustomMonitorInfo\($MONITOR_ID\)"
 		else
# 			echo "$response"
 			tickParse "$response"
 			nmon=``name``
			tag=``tag``
			type=``type``
# 			nm=`jsonval "$response" "name" `
# 			ret="$?"
# 			if [[ ($ret -ne 0) ]]
			if [[ (${#nmon} -le 0) ]]
 			then
	 			error 3 "The response contains no \"name\" key while getCustomMonitorInfo\($MONITOR_ID\)"
 			else
 				echo "Custom monitor name - $nmon ; tag - $tag ; type - $type ; ID - $MONITOR_ID"
 				MONITOR_NAME="$nmon"
 			fi
 		fi	
 	fi		
fi

echo "**** Getting data for monitor $nmon with id = $MONITOR_ID ****"

if [[ (${#file_prefix} -le 0) ]]
then
	file_prefix=$MONITOR_NAME
fi

file=$path"/"$file_prefix
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
			echo $response | sed 's/},{/\n/g' | sed 's/\[{//g' | sed 's/}\]//g' > $file"_"$d".log"
		fi
	fi
	timestamp=$(( $timestamp - (24*60*60) )) # calculates a previous day timestamp
done

