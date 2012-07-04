#!/bin/bash

# sorces included
source monitis_api.sh   || exit 2
source mon_measure.sh   || error 2 memcached_monitor.sh


# Use the Twitter API to get extended information of a given user, specified by ID or screen name
# usage: mon_start.sh -i <user ID> -s <user screen name> -d <duration in min>
# "User screen name" is used even in case of "user id" is specified also.
# default values (http://api.twitter.com/1/users/show.json?screen_name=monitis)
# s = monitis
# i = 17421289
# d = 5

while getopts "i:s:d:" opt;
do
	case $opt in
	i) id=$OPTARG ; echo Set user id to $USER_ID ;;
	s) name=$OPTARG ; echo Set user screen name to $USER_NAME ;;
	d) DURATION=$OPTARG ; echo Set duration to $DURATION min ;;
	*) echo "Usage: $0 -i <user ID> -s <user screen name> -d <duration in min>" 
	   error 4 "invalid parameter(s) while start"
	   ;;
	esac
done

if [[ ("x$name" != "x") ]] ; then
	USER_NAME="$name"
	USER_ID=""
elif [[ ("x$id" != "x") ]] ; then
	USER_ID="id"
	USER_NAME=""
else
	echo "ERROR: at least one of USER_NAME or USER_ID should be defined"
	error 4 "invalid parameter(s) while start"
fi

DURATION=$((60*$DURATION)) #convert to sec

MONITOR_NAME="Twitter:_User_"$USER_NAME"_"$USER_ID

echo "***Twitter Monitor start with following parameters***"
echo "Monitor name = $MONITOR_NAME"
echo "User = $USER_NAME $USER_ID"
echo "Duration for sending info = $DURATION sec"

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
	param=$(echo ${result} | awk -F "|" '{print $1}' )
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

