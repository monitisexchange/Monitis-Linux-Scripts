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

while true ; do
	echo "***$NAME - Monitor start with following parameters***" >&2
	echo "Monitor name = $MONITOR_NAME" >&2
	echo "Monitor tag = $MONITOR_TAG" >&2
	echo "Monitor type = $MONITOR_TYPE" >&2
	echo "Monitor ID = $MONITOR_ID" >&2
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
			add_custom_monitor "$MONITOR_NAME" "$MONITOR_TAG" "$RESULT_PARAMS" "$ADDITIONAL_PARAMS" "$MONITOR_TYPE"
			ret="$?"
			if [[ ($ret -ne 0) ]] ; then
				error "$ret" "$NAME - $MSG"
			else
				echo $NAME - Created custom monitor id = "$MONITOR_ID" >&2
				replaceInFile "monitis_global.sh" "MONITOR_ID" "$MONITOR_ID"
				echo "All is OK for now."
			fi	
		else
			echo $NAME - The custom monitor id = "$MONITOR_ID" >&2
			MONITOR_ID="$id"
			replaceInFile "monitis_global.sh" "MONITOR_ID" "$MONITOR_ID"	
		fi
	else
		#check correctness
		get_custom_monitor_info "$MONITOR_ID"
		ret="$?"
		if [[ ($ret -eq 0) ]] ; then
			echo $NAME - Correct custom monitor id = "$MONITOR_ID" >&2
			echo "All is OK for now."
		else #perhaps incorrect ID
			echo $NAME - $MSG >&2
			MONITOR_ID=0
			replaceInFile "monitis_global.sh" "MONITOR_ID" "$MONITOR_ID"
			continue
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
		MSG="???"
		get_token				# get new token in case of the existing one is too old
		ret="$?"
		if [[ ($ret -ne 0) ]] ; then	# some problems while getting token...
		    error "$ret" "$NAME - $MSG"
		    continue 
		fi
		if [[ (-e $COUNT_FILE) ]] ; then		# read counters
			attempt=2
			ret=1
			while [[ ($ret -ne 0) && ($attempt -gt 0) ]] ; do
				array=( `cat "$COUNT_FILE" `)
				ret="$?"
				((attempt--))		
			done
			if [[ ($ret -ne 0) ]] ; then	# problem with reading
				for (( i=0 ; i<= "${#PATTERNS[@]}" ; i++ )) ; do
				  array[$i]=0
				done			
				if test $DEBUG ; then
					error 10 "Problems with reading file \"$ret\""
				fi
			fi
			# Compose monitor data
			param=""
			for (( i=0 ; i <= "${#PATTERNS[@]}" ; i++ )) ; do
				t=$(( ${array[$i]} - ${prev_res[$i]} ))
				if [[ ($t -lt 0) ]] ; then
					t=0
				fi
	#			t=`echo "$t" | awk ' { if($1>=0) { print $1 } else { print 0 } }' `
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
			if test $DEBUG ; then
				error 10 "$NAME - The Custom monitor data were successfully added"
			fi
		fi
		else
			if test $DEBUG ; then
				error 10 "$NAME - problems with $COUNT_FILE"
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
done

