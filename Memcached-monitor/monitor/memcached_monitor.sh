#!/bin/bash

# sorces included
source monitor_constant.sh    || exit 2

declare -i initialized=0	# indicator of master variables initializing
#previous measurement data
declare    return_value

#Access to the Memcached located on remout or local host, 
# execute command and keep the result in the local file
#
#@param HOST {STRING} - remote host IP where Memcached is located
#@param PORT {INT} - remote Memcached listen port
#@param FILE {STRING} - file that receive the results
#
#echo -e 'stats\r' | nc localhost 11211
function access_memcached {
	local HOST=$1
	local PORT=$2
	local CMD=$3
	local FILE=$4
	if [[ ("x$FILE" != "x") ]] #file specified
	then	
		echo -e "$CMD" | nc -q 1 $HOST $PORT | tee $FILE > /dev/null
		ret="$?"
		if [[ ($ret -gt 0) || !(-r $FILE) || ($(stat -c%s $FILE) -le 0) ]]
		then
			return 1
		fi
	else
		echo -e "$CMD" | nc -q 1 $HOST $PORT
		ret="$?"
	fi
	return $ret
}

#  Format a timestamp into the form 'x day hh:mm:ss'
#  
#  @param TIMESTAMP {NUMBER} the timestamp in sec
# 
function formatTimestamp(){
	local time="$1"
	local sec=$(( $time%60 ))
	local min=$(( ($time/60)%60 ))
	local hr=$(( ($time/3600)%24 ))
	local da=$(( $time/86400 ))
	local str=$(echo `printf "%u.%02u.%02u" $hr $min $sec`)
	if [[ ($da -gt 0) ]]
	then
		str="$da day $str" 
	fi
	echo $str
}

#Function returns variable value from file
#
#@param FILENAME {STRING} - relative or absolute path to file 
#							where beforehand stored the variables set
#@param VAR {STRING} - searching variable name
#@param DELIMITER {CHAR} - separating delimiter
#sample:
#   $(extract_value mstatus auto_increment_offset)
function extract_value() {
    FILENAME=$1
    VAR=$2
    DELIMITER=$3
    if [ $DELIMITER ]
    then
	    grep -w $VAR $FILENAME | tr '\r' ' ' | awk -F $DELIMITER '{print $3}'    
    else
	    grep -w $VAR $FILENAME | tr '\r' ' ' | awk '{print $3}'
    fi
}

function get_measure() {
	MSG="OK"
	local errors=0

	if [ $initialized -eq 0 ]	# first time calling - initialize and get settings
	then
	  `rm -f $FILE_STATUS $FILE_STATUS_PREV $FILE_SETTING`
	  access_memcached "$MEMCACHED_IP" "$MEMCACHED_PORT" "$CMD_SETTING" "$FILE_SETTING"
	  if [[ ("$?" -gt 0) ]]
	  then
	    return_value=$UNAC_STATE
	    return 0
	  else
	  	initialized=1
	  fi
	fi

	#Current results
    access_memcached "$MEMCACHED_IP" "$MEMCACHED_PORT" "$CMD_STATUS" "$FILE_STATUS"
	if [[ ("$?" -gt 0) ]]
	then
	    return_value=$UNAC_STATE
	    initialized=0
    	return 0
    fi

	local curr_connections=$(extract_value $FILE_STATUS curr_connections) #Number of open connections
	local maxconns=$(extract_value $FILE_SETTING maxconns) 				#Number of max connections
	local get_hits=$(extract_value $FILE_STATUS get_hits) 				#Number of keys that have been requested and found present
	local get_misses=$(extract_value $FILE_STATUS get_misses) 			#Number of items that have been requested and not found
	local delete_hits=$(extract_value $FILE_STATUS delete_hits) 		#Number of keys that have been deleted and found present
	local delete_misses=$(extract_value $FILE_STATUS delete_misses)		#Number of items that have been deleted and not found
	local incr_hits=$(extract_value $FILE_STATUS incr_hits) 			#Number of keys that have been incremented and found present
	local incr_misses=$(extract_value $FILE_STATUS incr_misses)			#Number of items that have been incremented and not found
	local decr_hits=$(extract_value $FILE_STATUS decr_hits) 			#Number of keys that have been decremented and found present
	local decr_misses=$(extract_value $FILE_STATUS decr_misses)			#Number of items that have been decremented and not found
	local limit_maxbytes=$(extract_value $FILE_STATUS limit_maxbytes) 	#Number of bytes this server is allowed to use for storage
	local bytes=$(extract_value $FILE_STATUS bytes) 					#Current number of bytes used to store items
	local bytes_read=$(extract_value $FILE_STATUS bytes_read)			#Current number of bytes read
	local bytes_written=$(extract_value $FILE_STATUS bytes_written)		#Current number of bytes written
	local curr_items=$(extract_value $FILE_STATUS curr_items) 			#Current number of items stored
	local evics=$(extract_value $FILE_STATUS evictions)					#Number of valid items removed from cache to free memory for new items
	local uptime=$(extract_value $FILE_STATUS uptime)					#Number of secs since the server started  533034 
	
	#previous results
    if [[ !(-r "$FILE_STATUS_PREV") || ($(stat -c%s "$FILE_STATUS_PREV") -le 0) ]]
    then
    	`cp -u $FILE_STATUS $FILE_STATUS_PREV`
    fi
	local curr_connections_=$(extract_value $FILE_STATUS_PREV curr_connections) #Number of open connections
	local get_hits_=$(extract_value $FILE_STATUS_PREV get_hits) 				#Number of keys that have been requested and found present
	local get_misses_=$(extract_value $FILE_STATUS_PREV get_misses) 			#Number of items that have been requested and not found
	local delete_hits_=$(extract_value $FILE_STATUS_PREV delete_hits) 		#Number of keys that have been deleted and found present
	local delete_misses_=$(extract_value $FILE_STATUS_PREV delete_misses)	#Number of items that have been deleted and not found
	local incr_hits_=$(extract_value $FILE_STATUS_PREV incr_hits) 			#Number of keys that have been incremented and found present
	local incr_misses_=$(extract_value $FILE_STATUS_PREV incr_misses)		#Number of items that have been incremented and not found
	local decr_hits_=$(extract_value $FILE_STATUS_PREV decr_hits) 			#Number of keys that have been decremented and found present
	local decr_misses_=$(extract_value $FILE_STATUS_PREV decr_misses)		#Number of items that have been decremented and not found
	local limit_maxbytes_=$(extract_value $FILE_STATUS_PREV limit_maxbytes) #Number of bytes this server is allowed to use for storage
	local bytes_=$(extract_value $FILE_STATUS_PREV bytes) 					#Current number of bytes used to store items
	local bytes_read_=$(extract_value $FILE_STATUS_PREV bytes_read)			#Current number of bytes read
	local bytes_written_=$(extract_value $FILE_STATUS_PREV bytes_written)	#Current number of bytes written
	local curr_items_=$(extract_value $FILE_STATUS_PREV curr_items) 		#Current number of items stored
	local evics_=$(extract_value $FILE_STATUS_PREV evictions)				#Number of valid items removed from cache to free memory for new items

		#local curr_connections_=0
		#local get_hits_=0
		#local get_misses_=0
		#local delete_hits_=0
		#local delete_misses_=0
		#local incr_hits_=0
		#local incr_misses_=0
		#local decr_hits_=0
		#local decr_misses_=0
		#local limit_maxbytes_=0
		#local bytes_read_=0
		#local bytes_written_=0
		#local bytes_=0
		#local curr_items_=0
		#local evics_=0
	
#	Percent of open connections to max connections
	local conn=$(echo "scale=2;100*$curr_connections / $maxconns" | bc )
	if [[ ($((100*$curr_connections / $maxconns)) -gt 95) ]]
	then
		MSG[$errors]="WARN - The number of connections reached to maximum allowed"
		errors=$(($errors+1))	
	fi
			
#	Percent of items that have been requested and not found to total number of get commands 
	local lres=$(( $get_hits + $get_misses ))
	if [[ ($lres -le 0) ]]
	then
		local get_miss=$(echo "scale=2;(100.0*($get_misses - $get_misses_))" | bc )
		lres=$((100*($get_misses - $get_misses_)))	
	else
		local get_miss=$(echo "scale=2;(100*($get_misses - $get_misses_)/$lres)" | bc )
		lres=$((100*($get_misses - $get_misses_)/$lres))
	fi
	if [[ ($lres -gt 5) ]]
	then
		MSG[$errors]="WARN - too many requested to get but non-found (lost) records"
		errors=$(($errors+1))	
	fi
	
#	Percent of items that have been requested to delete and not found to total number of delete commands
	lres=$(( $delete_hits + $delete_misses ))
	if [[ ($lres -lt 1) ]]
	then
		local delete_miss=$(echo "scale=2;(100*$delete_misses)" | bc )
		lres=$((100*$delete_misses))
	else
		local delete_miss=$(echo "scale=2;(100*$delete_misses/$lres)" | bc )
		lres=$((100*$delete_misses/$lres))
	fi	
	if [[ ($lres -gt 10) ]]
	then
		MSG[$errors]="WARN - too many requested to delete but already deleted records"
		errors=$(($errors+1))	
	fi

#	Percent of items that have been requested to increase and not found to total number of increase commands
	lres=$(( $incr_hits + $incr_misses ))
	if [[ ($lres -le 0) ]]
	then
		local incr_miss=$(echo "scale=2;(100*$incr_misses)" | bc )
		lres=$((100*$incr_misses))
	else
		local incr_miss=$(echo "scale=2;(100*$incr_misses/$lres)" | bc )
		lres=$((100*$incr_misses/$lres))
	fi	
	if [[ ($lres -gt 5) ]]
	then
		MSG[$errors]="WARN - too many requested to increase but non-found (lost) records"
		errors=$(($errors+1))	
	fi
	
#	Percent of items that have been requested to decrease and not found to total number of decrease commands
	lres=$(( $decr_hits + $decr_misses ))
	if [[ ($lres -le 0) ]]
	then
		local decr_miss=$(echo "scale=2;(100*$decr_misses)" | bc )
		lres=$((100*$decr_misses))
	else
		local decr_miss=$(echo "scale=2;(100*$decr_misses/$lres)" | bc )
		lres=$((100*$decr_misses/$lres))
	fi	
	if [[ ($lres -gt 5) ]]
	then
		MSG[$errors]="WARN - too many requested to decrease but non-found (lost) records"
		errors=$(($errors+1))	
	fi
	
#	Percent of current number of bytes used to store items to the max accessible bytes
	local mem_usage=$(echo "scale=2;(100*$bytes/$limit_maxbytes)" | bc )
	if [[ ($((100*$bytes/$limit_maxbytes)) -gt 95) ]]
	then
		MSG[$errors]="WARN - the memory usage reached to critical point"
		errors=$(($errors+1))	
	fi
	
#	Percent of valid items removed from cache to free memory to current number of items stored
	if [[ ($curr_items -le 0) ]]
	then
		local evictions=0
		lres=0
	else
		local evictions=$(echo "scale=2;(100*($evics-$evics_)/$curr_items)" | bc )
		lres=$(( 100*($evics-$evics_)/$curr_items ))
	fi
	if [[ ($lres -gt 5) ]]
	then
		MSG[$errors]="WARN - Perhaps, the memory limit is to small"
		errors=$(($errors+1))	
	fi
	
#	Total number of keys that have been requested per sec.
	local reqs=$(echo "scale=2;((($get_hits +  $get_misses)-($get_hits_ +  $get_misses_)) / $DURATION)" | bc )

#	inbound written bytes per sec
	local inbound=$(echo "scale=2;(($bytes_written - $bytes_written_)/$DURATION/1000)" | bc )
	
#	inbound written bytes per sec
	local outbound=$(echo "scale=2;(($bytes_read - $bytes_read_)/$DURATION/1000)" | bc )

#	Memcached Uptime
	local upt=`formatTimestamp $uptime`
	if [[ -n "$upt" ]]
	then
		. monitis_util.sh
		upt=`uri_escape "$upt"`
	fi
	
	`mv $FILE_STATUS $FILE_STATUS_PREV `
		
	local details="details"
	if [[ ($errors -gt 0) ]]
	then
	    problem="Problems in memcached"
	    CNT=0
	    while [ "$CNT" != "$errors" ]
	    do
	        problem="$problem + ${MSG[$CNT]}"
	        CNT=$(($CNT+1))
	    done
	    details="$details+${problem}"
	    status="$FAIL_STATE"
	else
	    details="$details + Memcached OK"
	    lres=$(( ($get_hits +  $get_misses)-($get_hits_ +  $get_misses_) ))
	    details="$details + Memcached receive  $lres requests during $DURATION sec"
	    details="$details + Memcached use $curr_connections connections from available $maxconns"
	    details="$details + Memcached use $bytes bytes from available $limit_maxbytes"
	    status="$NORM_STATE"
	fi

	param="status:$status;conn:$conn;get_miss:$get_miss;delete_miss:$delete_miss;incr_miss:$incr_miss;decr_miss:$decr_miss;mem_usage:$mem_usage;evictions:$evictions;reqs:$reqs;in_kbps:$inbound;out_kbps:$outbound;uptime:$upt"
	return_value="$param | $details"
	return 0
}

