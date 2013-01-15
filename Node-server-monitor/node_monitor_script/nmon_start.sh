#!/bin/bash

# sorces included
source monitis_api.sh  || exit 2
source monitor_node.sh || error 2 monitor_node.sh

DURATION=$((60*$DURATION)) #convert to sec

echo "***$NAME - Monitor start with following parameters***"
echo "Monitor name = $MONITOR_NAME"
echo "Monitor tag = $MONITOR_TAG"
echo "Monitor type = $MONITOR_TYPE"
echo "Duration for sending info = $DURATION sec"

echo obtaining TOKEN
get_token
ret="$?"
if [[ ($ret -ne 0) ]]
then
	error 3 "$MSG"
else
	echo $NAME - RECEIVE TOKEN: "$TOKEN" at `date -u -d @$(( $TOKEN_OBTAIN_TIME/1000 ))`
	echo "All is OK for now."
fi

if [[ ($MONITOR_ID -gt 0) ]]
then 
	echo "$NAME - Monitor ID isn't ZERO - try to check correctness."
	get_custom_monitor_info "$MONITOR_ID"
	ret="$?"
	if [[ ($ret -ne 0) ]]
	then # not found monitor with given ID
		echo "$NAME - Monitor ID is incorrect - it cannot be used"
		MONITOR_ID=0
	else
		echo "$NAME - Monitor ID is correct - we will use it"
	fi
fi

if [[ ($MONITOR_ID -le 0) ]]
then
	echo $NAME - Adding custom monitor with parameters name: "$MONITOR_NAME" tag: "$MONITOR_TAG" type: "$MONITOR_TYPE" params: "$RESULT_PARAMS" a_params: "$ADDITIONAL_PARAMS" multiValue: "$MULTIVALUE"
	add_custom_monitor "$MONITOR_NAME" "$MONITOR_TAG" "$RESULT_PARAMS" "$ADDITIONAL_PARAMS" "$MONITOR_TYPE"
	ret="$?"
	if [[ ($ret -ne 0) ]]
	then
		error "$ret" "$NAME - $MSG"
	else
		echo $NAME - Custom monitor id = "$MONITOR_ID"
		echo "All is OK for now."
	fi
fi

if [[ ($MONITOR_ID -le 0) ]]
then 
	echo $NAME - MonitorId is still zero - try to obtain it from Monitis
	
	MONITOR_ID=`get_monitorID "$MONITOR_NAME" "$MONITOR_TAG" "$MONITOR_TYPE" `
	ret="$?"
	if [[ ($ret -ne 0) ]]
	then
		error "$ret" "$NAME - $MSG"
	else
		echo $NAME - Custom monitor id = "$MONITOR_ID"
		replaceInFile "monitis_global.sh" "MONITOR_ID" "$MONITOR_ID"
		echo "All is OK for now."
	fi
fi

# Periodically adding new data
echo "$NAME - Starting LOOP for adding new data"
while $(sleep "$DURATION")
do
	get_token				# get new token in case of the existing one is too old
	ret="$?"
	if [[ ($ret -ne 0) ]]
	then	# some problems while getting token...
		error "$ret" "$NAME - $MSG"
		continue
	fi
	get_measure				# call measure function
	ret="$?"
	echo $NAME - DEBUG ret = "$ret"  return_value = "$return_value"
	if [[ ($ret -ne 0) ]]
	then
	    error "$ret" "$NAME - $MSG"
#	    continue
	fi

	result=$return_value	# retrieve measure values
	# Compose monitor data
	param=$(echo ${result} | awk -F "|" '{print $1}')
	param=` trim $param `
	param=` uri_escape $param `
	#echo
	#echo $NAME - DEBUG: Composed params is \"$param\" >&2
	#echo
	timestamp=`get_timestamp`
	#echo
	#echo $NAME - DEBUG: Timestamp is \"$timestamp\" >&2
	#echo

	# Sending to Monitis
	add_custom_monitor_data $param $timestamp
	ret="$?"
	if [[ ($ret -ne 0) ]]
	then
		error "$ret" "$NAME - $MSG"
		if [[ ( -n ` echo $MSG | grep -asio -m1 "expired" `) ]] ; then
			get_token $TRUE		# force to get a new token
		fi
		continue
	else
		echo $( date +"%D %T" ) - $NAME - The Custom monitor data were successfully added

		# Now create additional data
		if [[ -z "${ADDITIONAL_PARAMS}" ]] ; then # ADDITIONAL_PARAMS is not set
			continue
		fi

		param=$(echo ${result} | awk -F "|" '{print $2}' )
		param=$(trim "$param")
		#echo $param
		isJSON "$param"
		ret="$?"
		if [[ ( $ret -ne 0 ) ]]
		then
			MSG="Seems, there is incorrect additional data string (no JSON string)"
			error "$ret" "$MSG - \'$param\'"
			continue
		fi
		# Transforming JSON string to array (first level only)
		array=`json2array "$param" `
		array_length="${#array[@]}"
		if [[ ($array_length -gt 0) ]]
		then
			param=`create_additional_param "${array[@]}" `
			ret="$?"
			if [[ ($ret -ne 0) ]]
			then
				error "$ret" "$param"
			else
				#echo
				#echo $NAME - DEBUG: Composed additional params is \"$param\" >&2
				#echo
				# Sending to Monitis
				add_custom_monitor_additional_data $param $timestamp
				ret="$?"
				if [[ ($ret -ne 0) ]]
				then
					error "$ret" "$NAME - $MSG"
				else
					echo $( date +"%D %T" ) - $NAME - The Custom monitor additional data were successfully added
				fi				
			fi
		else
			echo "$NAME - ****No any detailed records yet ($array_length)"
		fi			
	fi

done

