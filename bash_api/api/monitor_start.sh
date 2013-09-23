#!/bin/bash

# sorces included
source monitis_api.sh   || exit 2
source monitor.sh 		|| error 2 monitor.sh

#read argument; in this case the monitoring folders paths
while getopts "d:r:t:h" opt;
do
        case $opt in
		d) dur=$OPTARG 
			if [[ ($dur -gt 0) ]] ; then
			    echo Set duration to $dur min
			    DURATION=$dur
			fi
		;;
        r) range=$OPTARG ;;
        t) threshold="$OPTARG" ;;
        h) echo "Usage: $0 -d <duration in min> -r <range of random> -t <threshold value>" ; exit 0 ;;
        *) error 4 "Wrong parameter received" ;;
        esac
done

if [[ ("x$range" != "x") ]]
then
      RANGE="$range"
fi

if [[ ("x$threshold" != "x") ]]
then
	THRESHOLD="$threshold"
fi

DURATION=$((60*$DURATION)) #convert to sec

MONITOR_NAME="$NAME"_"$RANGE"

echo "***$NAME - Monitor start with following parameters***"
echo "Monitor name = $MONITOR_NAME"
echo "Monitor tag = $MONITOR_TAG"
echo "Monitor type = $MONITOR_TYPE"
echo "Monitor ID = $MONITOR_ID"
echo "Duration for sending info = $DURATION sec"

echo obtaining TOKEN
get_token
ret="$?"
if [[ ($ret -ne 0) ]]
then
	error 3 "$MSG"
else
	echo $NAME - RECEIVE TOKEN: "$TOKEN" at `date -u -d @$(( $TOKEN_OBTAIN_TIME/1000 ))` >&2
	echo "All is OK for now."
fi

#trying to get monitor id
id=`get_monitorID "$MONITOR_NAME" "$MONITOR_TAG" "$MONITOR_TYPE" `
ret="$?"
if [[ ($ret -ne 0) ]] ; then
	error 1 "$NAME - $MSG ( $ret )"
	#try to add new monitor
	echo $NAME - Adding custom monitor >&2
	add_custom_monitor "$MONITOR_NAME" "$MONITOR_TAG" "$RESULT_PARAMS" "$ADDITIONAL_PARAMS" "$MONITOR_TYPE"
	ret="$?"
	if [[ ($ret -ne 0) ]]
then
		error "$ret" "$NAME - $MSG"
	else
		echo $NAME - Custom monitor id = "$MONITOR_ID" >&2
		replaceInFile "monitis_global.sh" "MONITOR_ID" "$MONITOR_ID"
		echo "All is OK for now."
	fi
	else
		echo $NAME - Custom monitor id = "$MONITOR_ID" >&2
		replaceInFile "monitis_global.sh" "MONITOR_ID" "$MONITOR_ID"
		echo "All is OK for now."
	fi
fi

# Periodically adding new data
echo "$NAME - Starting LOOP for adding new data" >&2
while $(sleep "$DURATION")
do
	MSG="???"
	get_token				# get new token in case of the existing one is too old
	ret="$?"
	if [[ ($ret -ne 0) ]] ; then	# some problems while getting token...
		error "$ret" "$NAME - $MSG"
		continue
	fi
	get_measure				# call measure function
	ret="$?"
	echo $NAME - DEBUG ret = "$ret"  return_value = "$return_value"
	if [[ ($ret -ne 0) ]] ; then
	    error "$ret" "$NAME - $MSG"
#	    continue
	fi

	result=$return_value	# retrieve measure values
	# Compose monitor data
	param=$(echo ${result} | awk -F "|" '{print $1}' )
	param=` trim $param `
	param=` uri_escape $param `
	echo
	echo $NAME - DEBUG: Composed params is \"$param\" >&2
	echo
	timestamp=`get_timestamp`

	# Sending to Monitis
	add_custom_monitor_data "$param" "$timestamp"
	ret="$?"
	if [[ ($ret -ne 0) ]] ; then
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
		unset array
		OIFS=$IFS
		IFS='+'
		array=( $param )
		IFS=$OIFS
		array_length="${#array[@]}"
		if [[ ($array_length -gt 0) ]] ; then
			echo 
			echo $NAME - DEBUG: Composed additional params from \"${array[@]}\" >&2
			echo
			param=`create_additional_param array[@] `
			ret="$?"
			if [[ ($ret -ne 0) ]] ; then
				error "$ret" "$param"
			else
				echo
				echo $NAME - DEBUG: Composed additional params is \"$param\" >&2
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

