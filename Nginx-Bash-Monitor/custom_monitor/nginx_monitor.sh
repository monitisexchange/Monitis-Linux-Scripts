#!/bin/bash

# sorces included
source monitis_api.sh      || exit 2
source monitor_constant.sh || error 2 monitor_constant.sh

function isLiveProcess() {
	name=$1
	pid=`ps -efw | grep -i "$name" | grep -v grep | awk '{print $2} ' `
	if test "$pid" ;  then
	   return 0
	fi 
	return 1
}

function get_measure() {
	local file=$RES_FILE # records file 
	local file_=$file"_" # temporary file

	if [[ !( -e $file ) ]] ; then	# resulting file is not created yet
		# check the existence of process
	    isLiveProcess $NAME
		ret="$?"
	    if [[ ($ret -ne 0) ]] ; then  # not found running process
		   return_value="$DEAD_RESULT"
        else  # process is running (probably don't have any load)
		   return_value="$DUMMY_RESULT"
		fi
	else
		#echo 'RENAMING...(for processing)'
		`mv -f "$file" "$file_" `
		#local tmp=`cat $file_ `
		
		IFS_=$IFS
			IFS="|"	; declare -a ar=( `cat "$file_"`) 
		IFS=$IFS_
		
		local in_total=${ar[0]}  # count of input requests
		local o1_total=${ar[1]}
		local o1_1xx=${ar[2]}
		local o1_2xx=${ar[3]}
		local o1_3xx=${ar[4]}
		local o1_4xx=${ar[5]}
		local o1_5xx=${ar[6]}
		local o2_total=${ar[7]}
		local o2_1xx=${ar[8]}
		local o2_2xx=${ar[9]}
		local o2_3xx=${ar[10]}
		local o2_4xx=${ar[11]}
		local o2_5xx=${ar[12]}
		
		#local input=`echo $tmp | awk -F"|" '{print $1}'`  # count of input requests
		in_load=$(echo "scale=3;($in_total / $DURATION)" | bc )  # input load calculation [req/sec]
		o1_perc=$(echo "scale=1;(100 * $o1_total / $in_total)" | bc )
		o2_perc=$(echo "scale=1;(100 * $o2_total / $in_total)" | bc )
		o1_load=$(echo "scale=3;($o1_total / $DURATION)" | bc )  # Dest1 load calculation [req/sec]
		o2_load=$(echo "scale=3;($o2_total / $DURATION)" | bc )  # Dest2 load calculation [req/sec]
		o1_2xxp=0
		if [[ ( $o1_total -gt 0 ) ]] ; then			
			o1_2xxp=$(echo "scale=1;(100 * $o1_2xx / $o1_total)" | bc )  # Dest1 success processed requests (%)
		fi
		o2_2xxp=0
		if [[ ( $o2_total -gt 0 ) ]] ; then	
			o2_2xxp=$(echo "scale=1;(100 * $o2_2xx / $o2_total)" | bc )  # Dest2 load calculation [req/sec]
		fi
		
		local param="$OK_STATUS;in_load:$in_load;o1_load:$o1_load;o2_load:$o2_load;o1_perc:$o1_perc;o2_perc:$o2_perc;ok1:$o1_2xxp;ok2:$o2_2xxp"
		
		local details="details"
		details="$details + Nginx receive $in_total requests\n"
		details="$details + Nginx sent $o1_total requests to $DEST_HOST_1 ($c1xx:$o1_1xx;$c2xx:$o1_2xx;$c3xx:$o1_3xx;$c4xx:$o1_4xx;$c5xx:$o1_5xx)\n"
		details="$details + Nginx sent $o2_total requests to $DEST_HOST_2 ($c1xx:$o2_1xx;$c2xx:$o2_2xx;$c3xx:$o2_3xx;$c4xx:$o2_4xx;$c5xx:$o2_5xx)\n"
		
		return_value="$param | $details"
	fi
	return 0
}

if [[ !( -e $LOG_FILE ) ]]
then
	error 4 "Unreachible log file $LOG_FILE"
fi

echo "*** Monitor will be executed every $DURATION min ***"

DURATION=$((60*$DURATION)) #convert to sec

# remove temporary files
rm $RES_FILE > /dev/null

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
	
	MONITOR_ID=`get_monitorID "$MONITOR_NAME" "$MONITOR_TAG" "$MONITOR_TYPE" `
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
	ret="$?"
	if [[ ($ret -ne 0) ]]
	then	# some problems while getting token...
		error "$ret" "$MSG"
		continue
	fi
	get_measure				# call measure function
	ret="$?"
	if [[ ($ret -ne 0) ]]
	then
	    error "$ret" "$MSG"
#	    continue
	fi

	result=$return_value	# retrieve measure values
	# Compose monitor data
	param=$(echo ${result} | awk -F "|" '{print $1}')
	param=` trim $param `
	param=` uri_escape $param `
	#echo
	#echo DEBUG: Composed params is \"$param\" >&2
	#echo
	timestamp=`get_timestamp`
	#echo
	#echo DEBUG: Timestamp is \"$timestamp\" >&2
	#echo

	# Sending to Monitis
	add_custom_monitor_data $param $timestamp
	ret="$?"
	if [[ ($ret -ne 0) ]]
	then
		error "$ret" "$MSG"
		if [[ ( -n ` echo $MSG | grep -asio -m1 "expired" `) ]] ; then
			get_token $TRUE		# force to get a new token
		fi
		continue
	else
		echo $( date +"%D %T" ) - The Custom monitor data were successfully added

		# Now create additional data
		if [[ -z "${ADDITIONAL_PARAMS}" ]] ; then # ADDITIONAL_PARAMS is not set
			continue
		fi

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

