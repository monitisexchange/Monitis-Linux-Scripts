#!/bin/bash

# sorces included
source monitis_api.sh        || exit 2
source memcached_monitor.sh  || error 2 memcached_monitor.sh

#usage: mmon_start.sh -h <host_addres> -m <memcached access IP> -p <memcached access port> -d <duration in min>
# default values
# m = 127.0.0.1
# p = 11211
# d = 1

while getopts "h:m:p:d:" opt;
do
	case $opt in
	h) HOST_IP=$OPTARG ; echo Set host address to $HOST_IP ;;
	m) MEMCACHED_IP=$OPTARG ; echo Set memcached ip to $MEMCACHED_IP ;;
	p) MEMCACHED_PORT=$OPTARG ; echo Set memcached port to $MEMCACHED_PORT ;;
	d) dur=$OPTARG 
		if [[ ($dur -gt 0) ]] ; then
		    echo Set duration to $dur min
		    DURATION=$dur
		fi
	;;
	*) echo "Usage: $0 -h <host_addres> -m <memcached access aIP> -p <memcached access port> -d <duration in min>" 
	   error 4 "Wrong parameter received"
	   ;;
	esac
done

echo check memcached accessible
access_memcached "$MEMCACHED_IP" "$MEMCACHED_PORT" "get 0"
if [[ ("$?" -gt 0) ]] ; then
    error 1 "The specified memcached \( $MEMCACHED_IP:$MEMCACHED_PORT \) is not accessible!!!"
fi

DURATION=$((60*$DURATION)) #convert to sec

MONITOR_NAME="$NAME"_"$HOST_IP:$MEMCACHED_PORT"
FILE_SETTING="$FILE_SETTING$MEMCACHED_PORT"
FILE_STATUS="$FILE_STATUS$MEMCACHED_PORT"
FILE_STATUS_PREV="$FILE_STATUS_PREV$MEMCACHED_PORT"

while true ; do
	echo "***$NAME - Monitor start with following parameters***" >&2
	echo "Monitor name = $MONITOR_NAME" >&2
	echo "Monitor tag = $MONITOR_TAG" >&2
	echo "Monitor type = $MONITOR_TYPE" >&2
	echo "Monitor ID = $MONITOR_ID" >&2
	echo "Setting file = $FILE_SETTING" >&2
	echo "Status file = $FILE_STATUS" >&2
	echo "Previous status file = $FILE_STATUS_PREV" >&2
	echo "Duration for sending info = $DURATION sec" >&2
	echo "Sending into $SERVER" >&2

	ret=1
	while [ $ret -ne 0 ] ; do
		echo obtaining TOKEN
		get_token
		ret="$?"
		if [[ ($ret -ne 0) ]] ; then
			error "$ret" "$NAME - $MSG"
		fi
	done
	echo $NAME - RECEIVE TOKEN: "$TOKEN" at `date -u -d @$(( $TOKEN_OBTAIN_TIME/1000 ))` >&2
	echo "All is OK for now."
	
	if [[ ($MONITOR_ID -le 0) ]] ; then
		#trying to get monitor id
		id=`get_monitorID "$MONITOR_NAME" "$MONITOR_TAG" "$MONITOR_TYPE" `
		ret="$?"
		if [[ ($ret -ne 0) ]] ; then
			error 1 "$NAME - $MSG ( $ret )"
			#trying to add new monitor
			echo $NAME - Adding custom monitor >&2
			add_custom_monitor "$MONITOR_NAME" "$MONITOR_TAG" "$RESULT_PARAMS" "$ADDITIONAL_PARAMS" "$MONITOR_TYPE" "$MULTIVALUE"
			ret="$?"
			if [[ ($ret -ne 0) ]] ; then
				error "$ret" "$NAME - $MSG"
			else
				echo $NAME - Created custom monitor id = "$MONITOR_ID" >&2
				replaceInFile "monitis_global.sh" "MONITOR_ID" "$MONITOR_ID"
				echo "All is OK for now."
			fi	
		else
			MONITOR_ID="$id"
			echo $NAME - The custom monitor id = "$MONITOR_ID" >&2
			replaceInFile "monitis_global.sh" "MONITOR_ID" "$MONITOR_ID"	
		fi
	else
		#check correctness
		get_custom_monitor_info "$MONITOR_ID"
		ret="$?"
		if [[ ($ret -eq 0) ]] ; then
			isContains "$MSG" "\"$MONITOR_NAME\""
			ret="$?"
			if [[ ($ret -eq 0) ]] ; then
				echo $NAME - Correct custom monitor id = "$MONITOR_ID" >&2
				echo "All is OK for now."
			else 
				echo $NAME - Incorrect monitor ID, trying to get a correct one >&2
				MONITOR_ID=0
				replaceInFile "monitis_global.sh" "MONITOR_ID" "$MONITOR_ID"
				continue			
			fi
		else #perhaps incorrect ID
			echo $NAME - $MSG >&2
			MONITOR_ID=0
			replaceInFile "monitis_global.sh" "MONITOR_ID" "$MONITOR_ID"
			continue
		fi
	fi

	# Periodically adding new data
	echo "$NAME - Starting LOOP for adding new data" >&2
	file=$ERR_FILE # errors record file 
	file_=$file"_" # temporary file
	
	while $(sleep "$DURATION") ; do
		MSG="???"
		ret=1
		while [ $ret -ne 0 ] ; do
			get_token				# get new token in case of the existing one is too old
			ret="$?"
			if [[ ($ret -ne 0) ]] ; then	# some problems while getting token...
				error "$ret" "$NAME - $MSG"
			fi
		done
		get_measure				# call measure function
		ret="$?"
		echo $NAME - DEBUG ret = "$ret"  return_value = "$return_value"
		if [[ ($ret -ne 0) ]] ; then
		    error "$ret" "$NAME - $MSG"
	#	    continue
		fi
	
		result=$return_value	# retrieve measure values
		# Compose monitor data
		param=$(echo ${result} | awk -F "|" '{print $1}')
		param=` trim $param `
		param=` uri_escape $param `
#		param=` urlencode $param `
		echo
		echo $NAME - DEBUG: Composed params is \"$param\"
		echo
		timestamp=`get_timestamp`
	
		# Sending to Monitis
		add_custom_monitor_data "$param" "$timestamp"
		ret="$?"
		if [[ ($ret -ne 0) ]] ; then
			error "$ret" "$NAME - $MSG"
			if [[ ( -n ` echo $MSG | grep -asio -m1 "expire" `) ]] ; then
				get_token $TRUE		# force to get a new token
				add_custom_monitor_data "$param" "$timestamp"
				ret="$?"
			elif [[ ( -n ` echo $MSG | grep -asio -m1 "Invalid" `) ]] ; then
				break;
			fi
	#		continue
		else
			echo $( date +"%D %T" ) - $NAME - The Custom monitor data were added \($ret\)
			continue # don't send additional data separately

			# Now create additional data
			if [[ -z "${ADDITIONAL_PARAMS}" ]] ; then # ADDITIONAL_PARAMS is not set
				continue
			fi
	
			param=$(echo ${result} | awk -F "|" '{print $2}' )
			param=$(trim "$param")
			unset array
			OIFS=$IFS
			IFS='+'
			array=( $param )
			IFS=$OIFS
			array_length="${#array[@]}"
			if [[ ($array_length -gt 0) ]] ; then
				echo 
				echo $NAME - DEBUG: Composed additional params from \( ${array[@]} \)
				echo
				param=`create_additional_param "${array[@]}" `
				ret="$?"
				if [[ ($ret -ne 0) ]] ; then
					error "$ret" "$param"
				else
					echo
					echo $NAME - DEBUG: Composed additional params is \"$param\"
					echo
	
					# Sending to Monitis
					add_custom_monitor_additional_data "$param" "$timestamp"
					ret="$?"
					if [[ ($ret -ne 0) ]] ; then
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
done
