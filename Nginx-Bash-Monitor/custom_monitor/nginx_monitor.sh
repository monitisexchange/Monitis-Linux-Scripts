#!/bin/bash

# sorces included
source monitis_api.sh      || exit 2
source monitor_constant.sh || error 2 monitor_constant.sh

#usage: nginx_monitor.sh -d <duration in min>
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
    	*)    echo "Unrecognized parameter $1" >&2
			;; # unknown option		
  	esac
  	shift
done


declare -A hash

function isLiveProcess() {
	name=$1
	pid=`ps -efw | grep -i "$name" | grep -v grep | awk '{print $2} ' `
	if test "$pid" ;  then
	   return 0
	fi 
	return 1
}

function get_measure() {
	if [[ !( -e $LOG_FILE ) ]] ; then	# resulting file is not created yet
		# check the existence of process
	    isLiveProcess $NAME
		ret="$?"
	    if [[ ($ret -ne 0) ]] ; then  # not found running process
		   return_value="$DEAD_RESULT"
		   MSG="$NAME process doesn't exist"
		   return 1
        else  # process is running (probably don't have any load)
		   return_value="$DUMMY_RESULT"
		   MSG="$LOG_FILE doesn't exist"
		   return 1
		fi
	fi

	hash[$tot]=0
	hash[$successful]=0
	hash[${dir[0]}]=0
	hash[${dir[1]}]=0
	hash["${dir[0]}""$c1xx"]=0
	hash["${dir[1]}""$c1xx"]=0
	hash["${dir[0]}""$c2xx"]=0
	hash["${dir[1]}""$c2xx"]=0
	hash["${dir[0]}""$c3xx"]=0
	hash["${dir[1]}""$c3xx"]=0
	hash["${dir[0]}""$c4xx"]=0
	hash["${dir[1]}""$c4xx"]=0
	hash["${dir[0]}""$c5xx"]=0
	hash["${dir[1]}""$c5xx"]=0

#	mv $LOG_FILE $LOG_FILE"_"
	l=$(wc $LOG_FILE | echo `awk -F " " '{print $3}'`)
	tmp=`cat $LOG_FILE`
	truncate -s -$l $LOG_FILE
	echo "file in memory - $l"
	IFS_=$IFS
	IFS='
'
	for line in $tmp ; do #read line from log file	
		hash[$tot]=$((${hash[$tot]} + 1)) #increment total number of requests..
		for z in ${dir[@]} ; do # for every defined ip
			IFSO=$IFS
			IFS="#"
			ar=( $line )
			IFS=$IFSO
			code=${ar[0]}
			ip=${ar[1]}
			if [[ ("$code" -eq "$code") && ("x$ip" != "$ip" ) ]] 2>/dev/null ; then #check for code is number abd IP is exist
			    if [[ ("$ip" == "$z") ]] ; then #check whether the line contains the specified ip			
					hash[$z]=$((${hash[$z]}+1))  # increment the number of requests of specified ip 
					code=${ar[0]}
					if [[ ($code -lt 200) ]] ; then
						hash["$z""$c1xx"]=$((${hash["$z""$c1xx"]} + 1 ))
					elif [[ ($code -lt 300) ]] ; then
						hash["$z""$c2xx"]=$((${hash["$z""$c2xx"]} + 1 ))
						hash[$successful]=$((${hash[$successful]} + 1 )) #increment the total number of  successful requests
					elif [[ ($code -lt 400) ]] ; then
						hash["$z""$c3xx"]=$((${hash["$z""$c3xx"]} + 1 ))
					elif [[ ($code -lt 500) ]] ; then
						hash["$z""$c4xx"]=$((${hash["$z""$c4xx"]} + 1 ))
					else
						hash["$z""$c5xx"]=$((${hash["$z""$c5xx"]} + 1 ))
		            fi
	#       			echo "$line => ${ar[@]} code = ${ar[0]} ip =  ${ar[1]} $z => hash[$z]"
	       			break
			    fi
			else
				break
		    fi
		done
	done
	echo total = ${hash[$tot]}
	echo "0: ${hash["${dir[0]}"]} ${hash["${dir[0]}""$c1xx"]} ${hash["${dir[0]}""$c2xx"]} ${hash["${dir[0]}""$c3xx"]} ${hash["${dir[0]}""$c4xx"]} ${hash["${dir[0]}""$c5xx"]}"
	echo "1: ${hash["${dir[1]}"]} ${hash["${dir[1]}""$c1xx"]} ${hash["${dir[1]}""$c2xx"]} ${hash["${dir[1]}""$c3xx"]} ${hash["${dir[1]}""$c4xx"]} ${hash["${dir[1]}""$c5xx"]}"

	IFS=$IFS_
	
	local in_total=${hash[$tot]}  # count of input requests
	local o1_total=${hash["${dir[0]}"]}
	local o1_1xx=${hash["${dir[0]}""$c1xx"]}
	local o1_2xx=${hash["${dir[0]}""$c2xx"]}
	local o1_3xx=${hash["${dir[0]}""$c3xx"]}
	local o1_4xx=${hash["${dir[0]}""$c4xx"]}
	local o1_5xx=${hash["${dir[0]}""$c5xx"]}
	local o2_total=${hash["${dir[1]}"]}
	local o2_1xx=${hash["${dir[1]}""$c1xx"]}
	local o2_2xx=${hash["${dir[1]}""$c2xx"]}
	local o2_3xx=${hash["${dir[1]}""$c3xx"]}
	local o2_4xx=${hash["${dir[1]}""$c4xx"]}
	local o2_5xx=${hash["${dir[1]}""$c5xx"]}
	
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
	return 0
}

DURATION=$((60*$DURATION)) #convert to sec

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
	while $(sleep "$DURATION") ; do
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
		param=$(echo ${result} | awk -F "|" '{print $1}')
		param=` trim $param `
		param=` uri_escape $param `
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
				echo "$NAME - DEBUG: Composed additional params from ( ${array[@]} )"
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
