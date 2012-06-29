#!/bin/bash

# sorces included
source monitis_api.sh      || exit 2
source monitor_constant.sh || error 2 monitor_constant.sh

declare    return_value

function get_measure() {

start=$(( `date -u +%s%N`))
resp=$(radtest "$TESTUSER" "$TESTPASSWORD" "$HOST" "$PORT" "$SECRET" >aaa.txt 2> temp.txt)
end=$(( `date -u +%s%N`))
diff=$(($end-$start))
seconds=$(echo "scale=3;$diff/1000000000" | bc )

status="";

if grep -q Access-Accept <aaa.txt; then
	status="$OK";
	return_value="status:$status;reqTime:$seconds"
        rm aaa.txt
elif grep -q Access-Reject <aaa.txt; then
	status="$NOK"
	return_value="status:$status;reqTime:$seconds"
        rm aaa.txt
elif grep -q "radclient: no response" <temp.txt; then
	status="$DEAD"
	return_value="status:$status"
        rm temp.txt
fi

}


DURATION=$((60*$DURATION)) #convert to sec

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

# Adding custom monitor
add_custom_monitor "$MONITOR_NAME" "$MONITOR_TAG" "$RESULT_PARAMS" "$ADDITIONAL_PARAMS" "$MONITOR_TYPE"
ret="$?"
if [[ ($ret -ne 0) ]]
then
	error "$ret" "$MSG"
else
	echo Custom monitor id = "$MONITOR_ID"
	echo "All is OK for now."
fi

if [[ ($MONITOR_ID -le 0) ]]
then
	echo MonitorId is still zero - try to obtain it from Monitis

	MONITOR_ID=`get_monitorID $MONITOR_NAME $MONITOR_TAG $MONITOR_TYPE `
	ret="$?"
	if [[ ($ret -ne 0) ]]
	then
		error "$ret" "$MSG"
	else
		echo Custom monitor id = "$MONITOR_ID"
		echo "All is OK for now."
	fi
fi

# Periodically adding new data
while $(sleep "$DURATION")
do
	get_token				# get new token in case of the existing one is too old
	ret="$1"
	if [[ ($ret -ne 0) ]]
	then	# some problems while getting token...
		error "$ret" "$MSG"
		continue
	fi
	get_measure				# call measure function
	ret="$1"
	if [[ ($ret -ne 0) ]]
	then
	    error "$ret" "$MSG"
	    continue
	fi

	result=$return_value	# retrieve measure values
	# Compose monitor data
	param=$(echo ${result} | awk -F "|" '{print $1}' )
	#echo
	#echo DEBUG: Composed params is \"$param\" >&2
	#echo
	timestamp=`get_timestamp`
	# Sending to Monitis
	add_custom_monitor_data $param $timestamp
	ret="$?"
	if [[ ($ret -ne 0) ]]
	then
		error "$ret" "$MSG"
		continue
	else
		echo $( date +"%D %T" ) - The Custom monitor data were successfully added
		# Now create additional data
		param=$(echo ${result} | awk -F "|" '{print $2}' )
		unset array
		OIFS=$IFS
		IFS='+'
		array=( $param )
		IFS=$OIFS
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
				#echo DEBUG: Composed additional params is \"$param\" >&2
				#echo
				# Sending to Monitis
				add_custom_monitor_additional_data $param $timestamp
				ret="$?"
				if [[ ($ret -ne 0) ]]
				then
					error "$ret" "$MSG"
				else
					echo $( date +"%D %T" ) - The Custom monitor additional data were successfully added
				fi
			fi
		else
			echo "****No any detailed records yet ($array_length)"
		fi
	fi


done

