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
			   echo "Unrecognized parameter $1"
			   exit 1 
			fi
			;; # unknown option		
  	esac
  	shift
done

DURATION=$((60*$DURATION)) #convert to sec

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
	echo $NAME - Adding custom monitor with parameters name: "$MONITOR_NAME" tag: "$MONITOR_TAG" type: "$MONITOR_TYPE" params: "$RESULT_PARAMS" a_params: "$ADDITIONAL_PARAMS"
	add_custom_monitor "$MONITOR_NAME" "$MONITOR_TAG" "$RESULT_PARAMS" "$ADDITIONAL_PARAMS" "$MONITOR_TYPE"
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
file=$ERR_FILE # errors record file 
file_=$file"_" # temporary file
rep_count=3	   # the count of repetitions	

while $(sleep "$DURATION")
do
	get_token				# get new token in case of the existing one is too old
	ret="$?"
	if [[ ($ret -ne 0) ]]
	then	# some problems while getting token...
	    error "$ret" "$NAME - $MSG"
#	    continue
	fi
	if [[ -e "$file" ]]	# err file must exist!!!
	then
		echo 'RENAMING...(for processing)'
		mv -f "$file" "$file_"
		if [ "$?" -ne "0" ]
		then
			if [[ ($rep_count -gt 0) ]] ; then
				error 1 "Couldn't rename... "
				rep_count=$(( rep_count--))
				continue
			else
				error 3 "Couldn't rename after few tries ... "
			fi
		else
			echo -n "" >> $ERR_FILE	#recreate empty temporary file (if not exit yet)
			rep_count=3
			#read into array
			unset array
			while read line ; do
				array[${#array[@]}]="$line"
			done < $file_
			array_length="${#array[@]}"
			if [[ ($array_length -gt 0) ]]
			then
				# Compose monitor data
				param="events:$array_length;$OK_RESULT"
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
				fi
				echo $( date +"%D %T" ) - $NAME - The Custom monitor data were successfully added

				# Now create additional data
				if [[ -z "${ADDITIONAL_PARAMS}" ]] ; then # ADDITIONAL_PARAMS is not set
					continue
				fi

				param=`create_additional_param "${array[@]}"`
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
						error "$ret" "$NAME - $MSG"
					else
						echo $( date +"%D %T" ) - $NAME - The Custom monitor additional data were successfully added
					fi
				fi				
			else
				echo ****No any interesting new records yet - sent "0" as data
				# Sending DUMMY data to Monitis 
				add_custom_monitor_data "$DUMMY_RESULT"
				ret="$?"
				if [[ ($ret -eq 0) ]]
				then
					echo **** "$NAME" - Succesfully added dummy data
				else
					error "$ret" "$NAME - $MSG"
				fi
			fi
		fi
	else
		echo **** "$NAME" No any new records yet contain log file \(or not exist\) 
		# Sending DUMMY data to Monitis 
		add_custom_monitor_data "$FAIL_RESULT"
		ret="$?"
		if [[ ($ret -eq 0) ]]
		then
			echo **** "$NAME" Added failed data
		else
			error "$ret"  "$NAME" - "$MSG"
		fi
	fi

done

