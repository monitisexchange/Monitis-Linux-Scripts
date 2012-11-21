#!/bin/bash

# sorces included
source monitor_constant.sh    || exit 2

#previous measurement data
declare -i prev_time=0
declare    return_value

#Access to the MySQL, execute command and keep the result in the file
#
#@param HOST {STRING} - Host where located MySQL server
#@param USER {STRING} - MySQL user name
#@param PSWD {STRING} - MySQL user password
#@param CMD {STRING} - executed command on remote MySQL
#@param FILE {STRING} - file that receive the results
function access_MySQL {
	local HST=$1 ; shift
	local USR=$1 ; shift
	local PSWD=$1 ; shift
	local CMD=$1 ; shift
	local FILE=$1
	mysql -h "$HST" -u "$USR" -p"$PSWD" -e "$CMD" | tee "$FILE" > /dev/null
	local ret="$?"
	if [[ ($ret -gt 0) ]]
	then
		return 1
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
	local str=$(echo `printf "%02u.%02u.%02u" $hr $min $sec`)
	if [[ ($da -gt 0) ]]
	then
		str="$da""-""$str" 
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
	    grep -w $VAR $FILENAME | tr '\r' ' ' | awk -F $DELIMITER '{print $2 $3}'    
    else
	    grep -w $VAR $FILENAME | tr '\r' ' ' | awk '{print $2 $3}'
    fi
}

function get_slow_queries(){
	slow=$(mysqldumpslow -s c -t 5 )
	local pattern="Count:"
	local replaser=' + '${pattern}
	slow=${slow//$pattern/$replaser}
	echo $slow
}

function get_measure() {
	local details="details"

	#echo "********** check MySQL parameters **********"
	access_MySQL $HOST $USER $PASSWORD  "SHOW GLOBAL STATUS" status
	local ret_s="$?"
	if [[ (ret_s -gt 0) || ($(stat -c%s status) -le 0) ]]
	then
		MSG="Unknown problems while access mysql..."
		problem="FATAL "+"$MSG"
		details="$details+${problem}"
		return_value="$RESP_DOWN | $details"
		return 1
	fi
	
	access_MySQL $HOST $USER $PASSWORD  "SHOW GLOBAL VARIABLES" variables
	
	
	#echo "*********** Retriving status data ***********"
	local Bytes_received=$(extract_value status Bytes_received)
	local Bytes_sent=$(extract_value status Bytes_sent)
	local Com_insert=$(extract_value status Com_insert)
	local Com_select=$(extract_value status Com_select)
	local Com_update=$(extract_value status Com_update)
	local Com_delete=$(extract_value status Com_delete)
	local Com_show_status=$(extract_value status Com_show_status)
	local Com_show_variables=$(extract_value status Com_show_variables)
	local Connections=$(extract_value status Connections)
	local Queries=$(extract_value status Queries)
	local Slow_queries=$(extract_value status Slow_queries)
	local Threads_connected=$(extract_value status Threads_connected)
	local Threads_running=$(extract_value status Threads_running)
	local Uptime=$(extract_value status Uptime)
	local max_connections=$(extract_value variables max_connections)
	local slow_query_log=$(extract_value variables slow_query_log)
	local slow_query_log_file=$(extract_value variables slow_query_log_file)
	local long_query_time=$(extract_value variables long_query_time)
	
	local time_stamp=`date -u +%s` 		#current timestamp in sec
	local dur=$DURATION
	if [[ ($prev_time -gt 0) ]] ; then
		dur=$(( $time_stamp - $prev_time ))
	fi
		
	if [[ ($prev_time -eq 0) || !(-r pstatus) || ($(stat -c%s pstatus) -le 0) ]] # No yet previous results
    then
	 	local pBytes_received=$Bytes_received
		local pBytes_sent=$Bytes_sent
		local pCom_insert=$Com_insert
		local pCom_select=$Com_select
		local pCom_update=$Com_update
		local pCom_delete=$Com_delete
		local pCom_show_status=$Com_show_status
		local pCom_show_variables=$Com_show_variables
		local pConnections=$Connections
		local pQueries=$Queries
		local pSlow_queries=$Slow_queries
		local pThreads_connected=$Threads_connected
	else
		local pBytes_received=$(extract_value pstatus Bytes_received)
		local pBytes_sent=$(extract_value pstatus Bytes_sent)
		local pCom_insert=$(extract_value pstatus Com_insert)
		local pCom_select=$(extract_value pstatus Com_select)
		local pCom_update=$(extract_value pstatus Com_update)
		local pCom_delete=$(extract_value pstatus Com_delete)
		local pCom_show_status=$(extract_value pstatus Com_show_status)
		local pCom_show_variables=$(extract_value pstatus Com_show_variables)
		local pConnections=$(extract_value pstatus Connections)
		local pQueries=$(extract_value pstatus Queries)
		local pSlow_queries=$(extract_value pstatus Slow_queries)
		local pThreads_connected=$(extract_value pstatus Threads_connected)	
    fi
	
	
	# Copy the current result as previous one
	cp -f status pstatus
	prev_time=$time_stamp
	
	local Com_show_status_dif=$(( $Com_show_status - $pCom_show_status ))
	local Com_show_variables_dif=$(( $Com_show_variables - $pCom_show_variables ))

	local Bytes_received_dif=$(( $Bytes_received - $pBytes_received ))
	local KBytes_received_dif_ps=$(echo "scale=3; $Bytes_received_dif/1024/$dur" | bc )
	local Bytes_sent_dif=$(( $Bytes_sent - $pBytes_sent ))
	local KBytes_sent_dif_ps=$(echo "scale=3; $Bytes_sent_dif/1024/$dur" | bc )
	local Com_insert_dif_ps=$(echo "scale=3; ( $Com_insert - $pCom_insert )/$dur" | bc )
	local Com_select_dif_ps=$(echo "scale=3; ( $Com_select - $pCom_select )/$dur" | bc )
	local Com_update_dif_ps=$(echo "scale=3; ( $Com_update - $pCom_update )/$dur" | bc )
	local Com_delete_dif_ps=$(echo "scale=3; ( $Com_delete - $pCom_delete )/$dur" | bc )
	local Queries_dif_ps=$(echo "scale=3; ( $Queries - $pQueries )/$dur" | bc )
	local Slow_queries_dif=$(( $Slow_queries - $pSlow_queries ))
	local Connections_usage=$(echo "scale=1; 100 * $Threads_connected/$max_connections" | bc )
	local up=$(formatTimestamp $Uptime )
	
	#echo "*********** Analyzing ****************"
	local status="OK"
	
	errors=0
	if [[ $(($Bytes_received_dif + $Bytes_sent_dif)) -le 0 ]]
	then
	    MSG[$errors]="WARNING - MySQL is in IDLE state"
	    errors=$(($errors+1))
	    status="IDLE"
	fi
	
	if [[ $Slow_queries_dif -gt 0 ]]
	then
	    MSG[$errors]="Warning - the slow queries detected \(processing longer than $long_query_time sec\)"
	    if [[ ("$slow_query_log" != "OFF") && ( ("$HOST" == "localhost") || ("$HOST" == "127.0.0.1") ) ]]
	    then
	    	local slow=$(get_slow_queries)
	    	`>$slow_query_log_file`
	    	MSG[$errors]=${MSG[$errors]}$slow
	    fi
	    errors=$(($errors+1))
	    status="SLOW_QUERY"
	fi
		
	if [ $errors -gt 0 ]
	then
	    problem="Problems detected"
	    CNT=0
	    while [ "$CNT" != "$errors" ]
	    do
	        problem="$problem + ${MSG[$CNT]}"
	        CNT=$(($CNT+1))
	    done
	    details="$details+${problem}"
	else
	    details="$details + ""MySQL is OK"
	    #details="$details + Master writes to $Master_binlog_file ($Master_binlog_pos) with rate $Master_load pos/sec"
	    #details="$details + Slave reads from $Slave_read_binlog_file ($Slave_read_binlog_pos) with rate $Slave_load pos/sec"	
	fi
	local param="status:$status;receive:$KBytes_received_dif_ps;send:$KBytes_sent_dif_ps;insert:$Com_insert_dif_ps;select:$Com_select_dif_ps;update:$Com_update_dif_ps;delete:$Com_delete_dif_ps"
	param=$param";queries:$Queries_dif_ps;slow_queries:$Slow_queries_dif;thread_running:$Threads_running;thread_connected:$Threads_connected;Connections_usage:$Connections_usage;uptime:$up"
	return_value="$param | $details"
	return 0
}
