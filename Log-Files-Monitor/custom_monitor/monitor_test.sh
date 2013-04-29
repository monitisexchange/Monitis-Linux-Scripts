#!/bin/bash

# sorces included
source monitis_api.sh      || exit 2
source monitor_constant.sh || error 2 monitor_constant.sh

#usage: monitor_test.sh -d <duration in min>
# default values 
# 		d = 5 min
#parse command line
while [ $# -gt 0 ]    # Until run out of parameters . . .
do
	case $1 in
    	-h | --help ) 		echo "Usage: $0 -d <duration in min>" ; exit 0 ;;
    	-d | --duration )  	dur=$2 
							if [[ ($dur -gt 0) ]] ; then
							    echo Set duration to $dur min
							    DURATION=$dur
							fi	; 
							shift	;;
    	*)  # it can be file path
    		if [[ !(-r "$1") ]] ; then
			   echo "Unrecognized parameter $1" >&2
#			   exit 1 
			fi
			;; # unknown option		
  	esac
  	shift
done

DURATION=$((60*$DURATION)) #convert to sec

# forms the result params
RESULT_PARAMS="status:status::3;event0:Line_count::2"
for (( i=1 ; i<= "${#PATTERNS[@]}" ; i++ )) ; do
	t=${PATTERNS[$(( i - 1))]}
	t=`replBlank "$t" `
	RESULT_PARAMS="$RESULT_PARAMS;event$i:${t}_count::2"
done
#calculates checksum and add it to the name
checksum=`echo "$RESULT_PARAMS" | cksum | awk '{print $1}' `
MONITOR_NAME="$MONITOR_NAME"_$checksum

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

if [[ ($MONITOR_ID -gt 0) ]]
then 
	echo "$NAME - Monitor ID \"${MONITOR_ID}\" isn't ZERO - try to check correctness." >&2
	get_custom_monitor_info "$MONITOR_ID"
	ret="$?"
	if [[ ($ret -ne 0) ]]
	then # not found monitor with given ID
		echo "$NAME - Monitor ID is incorrect - it cannot be used" >&2
		MONITOR_ID=0
	else
		echo "$NAME - Monitor ID is correct - we will use it" >&2
	fi
fi

if [[ ($MONITOR_ID -le 0) ]]
then
	echo $NAME - Adding custom monitor with parameters name: "$MONITOR_NAME" tag: "$MONITOR_TAG" type: "$MONITOR_TYPE" params: "$RESULT_PARAMS" >&2
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
fi

if [[ ($MONITOR_ID -le 0) ]]
then 
	echo $NAME - MonitorId is still zero - try to obtain it from Monitis >&2
	
	MONITOR_ID=`get_monitorID "$MONITOR_NAME" "$MONITOR_TAG" "$MONITOR_TYPE" `
	ret="$?"
	if [[ ($ret -ne 0) ]]
	then
		error "$ret" "$NAME - $MSG"
	else
		echo $NAME - Custom monitor id = "$MONITOR_ID" >&2
		replaceInFile "monitis_global.sh" "MONITOR_ID" "$MONITOR_ID"
		echo "All is OK for now."
	fi
fi

# Periodically adding new data
echo "$NAME - Starting LOOP for adding new data" >&2

declare -a prev_res
for (( i=0 ; i<= "${#PATTERNS[@]}" ; i++ )) ; do
  prev_res[$i]=0
done	

while $(sleep "$DURATION")
do
	get_token				# get new token in case of the existing one is too old
	ret="$?"
	if [[ ($ret -ne 0) ]]
	then	# some problems while getting token...
	    error "$ret" "$MSG"
#	    continue
	fi
	if [[ (-e $COUNT_FILE) ]] ; then		# read counters
		array=( `cat "$COUNT_FILE" `)
		# Compose monitor data
		param=""
		for (( i=0 ; i<= "${#PATTERNS[@]}" ; i++ )) ; do
			t=$(( ${array[$i]} - ${prev_res[$i]} ))
			t=`echo "$t" | awk ' { if($1>=0) { print $1} else {print 0 }}' `
			if [[ ($i -eq 0) ]] ; then
			  t0=$t
			fi
			param="$param""event$i:$t;"
			prev_res[$i]=${array[$i]}
		done
		if [[ ($t0 -eq 0) ]] ; then
		  param="$param""$DUMMY_RESULT"
		else
		  param="$param""$OK_RESULT"
		fi
		if test $DEBUG ; then
			error 10 "Composed params is \"$param\""
		fi
		
		timestamp=`get_timestamp`
		
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
		fi
		if test $DEBUG ; then
			error 10 "$NAME - The Custom monitor data were successfully added"
		fi
	else
		if test $DEBUG ; then
			error 10 "$NAME - No any new records yet"
		fi	
		# Sending DUMMY data to Monitis 
		add_custom_monitor_data "$DUMMY_RESULT"
		ret="$?"
		if [[ ($ret -eq 0) ]]
		then
			if test $DEBUG ; then
				error 10 "$NAME - Succesfully added dummy data"
			fi			
		else
			error "$ret" "$NAME - $MSG"
		fi
	fi
done

