#!/bin/bash

# sorces included
source monitor_constant.sh    || exit 2

declare    return_value

#Validate Process parameters
#@return 0 - success
#@return 1 - PROC_ID is changed (m.b. restarted)
#@return 2 - process down
#@return 4 - No execution command for PROC_ID
#@return 8 - Nor PROC_CMD or PROC_ID is defined
function validate() {
	MSG=""
	local ret=0
	if [[ ( "x$PROC_CMD" != "x" ) ]] #PROC_CMD is defined
	then
		pid=`ps -efw | grep -i "$PROC_CMD" | grep -v grep | awk '{print $2} ' `
		if test "$pid" ;  then
			array=( $pid )
			if [[ ( "x$PROC_ID" != "x" ) ]] #PROC_ID is defined also
			then
				ret=1 #error Incorrect PROC_ID (m.b. restarted)
				for i in "${array[@]}"
				do
					if [[ ( $i -eq $PROC_ID ) ]]
					then
						ret=0
						break;
					fi
				done
				if [[ ($ret -gt 0) ]]
				then
					MSG="INCORRECT PID ( $PROC_ID ) for $PROC_CMD (found ${array[@]} ) - m.b. restarted"
					PROC_ID=${array[0]}
				fi
			fi
		else
			ret=2 #process down
			MSG="NO execution for command $PROC_CMD (m.b. DOWN)"
		fi
	elif [[ ( "x$PROC_ID" != "x" ) ]] #PROC_ID is defined
	then
		if [[ ( -f /proc/$PROC_ID/comm ) ]]
		then
			ret=0
			PROC_CMD=$( cat /proc/$PROC_ID/comm )
			MSG="PID is $PROC_ID for $PROC_CMD"
		else
			ret=4 #error No execution command for PROC_ID
			MSG="No execution command for PID "$PROC_ID
		fi
	else
		ret=8 #Nor PROC_CMD and PROC_ID is defined
		MSG="Nor PROC_CMD and PROC_ID is defined"
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
		str="$da-$str" 
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
	    grep -w $VAR $FILENAME | awk -F $DELIMITER '{print $2 $3}'    
    else
	    grep -w $VAR $FILENAME | awk '{print $2 $3}'
    fi
}

function get_measure() {
	local details="details"

	#echo "********** Validate **********"
	validate
	local ret="$?"
	if [[ ($ret -gt 1) && ($ret -lt 4) ]]
	then
		MSG="Process is DOWN..."
		problem="FATAL "+"$MSG"
		details="$details+${problem}"
		return_value="$RESP_DOWN | $details"
		return 1
	elif [[ ($ret -ge 4) ]]
	then
		MSG="No execution command for PID $PROC_ID or invalide parameters"
		return 16
	fi
	
	local lsof=$( lsof -p$PROC_ID )
	ofd=$( echo "$lsof" | wc -l )
	osd=$( echo "$lsof" | grep -iE "tcp | udp | ipv" | wc -l )
	local ofdm=$( ulimit -n )
	local ofd_pr=$(echo "scale=1; 100 * $ofd / $ofdm" | bc )
	
	local FDSize=$(extract_value /proc/$PROC_ID/status FDSize :)
	FDSize=` trim "$FDSize" `
	local VmPeak=$(extract_value /proc/$PROC_ID/status VmPeak :)
	local VmSize=$(extract_value /proc/$PROC_ID/status VmSize :)
	local virt=$( echo $VmSize | awk '{print $1}')
	local virtmb=$(echo "scale=3; $virt / 1024" | bc )
	local VmHWM=$(extract_value /proc/$PROC_ID/status VmHWM :)
	local VmRSS=$(extract_value /proc/$PROC_ID/status VmRSS :)
	local res=$( echo $VmRSS | awk '{print $1}')
	local resmb=$(echo "scale=3; $res / 1024" | bc )
	local VmData=$(extract_value /proc/$PROC_ID/status VmData :)
	local data=$( echo $VmData | awk '{print $1}')
	local VmStk=$(extract_value /proc/$PROC_ID/status VmStk :)
	local stack=$( echo $VmStk | awk '{print $1}')
	local VmExe=$(extract_value /proc/$PROC_ID/status VmExe :)
	local Threads=$(extract_value /proc/$PROC_ID/status Threads :)
	Threads=` trim "$Threads" `

	local cm=( $( ps -p$PROC_ID -o %cpu,%mem | grep -v % ) )
	local cpu_pr=${cm[0]}
	local mem_pr=${cm[1]}
	
	local uptime=$( ps -o etime $PROC_ID | grep -v ELAPSED )
	uptime=` trim "$uptime" `
	uptime=${uptime//:/.}

	#echo "*********** Analizing ****************"
	local status="OK"
	
	errors=0
	local tmp=$(( 100 * $ofd / $ofdm ))
	if [[ $tmp -gt 95 ]]
	then
	    MSG[$errors]="WARNING - too much open file descriptors"
	    errors=$(($errors+1))
	    status="NOK"
	fi

	
	if [[ ( ${cpu_pr/.*} -gt 95 ) || ( ${mem_pr/.*} -gt 95 ) ]]
	then
	    MSG[$errors]="WARNING - too much used resources"
	    errors=$(($errors+1))
	    status="NOK"
	fi

		
	if [ $errors -gt 0 ]
	then
	    problem="Problems detected"
	    CNT=0
	    while [[ ("$CNT" != "$errors") ]]
	    do
	        problem="$problem + ${MSG[$CNT]}"
	        CNT=$(($CNT+1))
	    done
	    details="$details+${problem}"
	else
	    details="$details + VmPeak:$VmPeak"
	    details="$details + VmHWM:$VmHWM"
	    details="$details + VmData:$VmData"
	    details="$details + VmStk:$VmStk"
	fi
	local param="status:$status;cpu:$cpu_pr;mem:$mem_pr;virt:$virtmb;res:$resmb;ofd:$ofd;osd:$osd;ofd_pr:$ofd_pr;threads:$Threads;uptime:$uptime"

	return_value="$param | $details"
	return 0
}
