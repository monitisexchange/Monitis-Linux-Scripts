#!/bin/bash

# sorces included
source monitor_constant.sh    || exit 2
source monitis_util.sh		  || exit 2

function trim() {
	echo $*
}

#Validate Process parameters
#@return 0 - success
#@return 1 - PROC_ID is changed (m.b. restarted)
#@return 2 - process down
#@return 4 - No execution command for PROC_ID
#@return 8 - Nor PROC_CMD or PROC_ID is defined
function validate() {
	MSG=""
	local ret=0
	if [[ ( "x$PROC_CMD" != "x" ) ]] ; then #PROC_CMD is defined (ignore defined ID)
		pid=`ps -ef | grep -i "$PROC_CMD" | grep -v grep | grep -v "monitor_start" | awk '{print $2} ' `
		if test "$pid" ;  then #at least one pid is found
			PROC_ID="$(echo "$pid"| tr '\n' ' ' | trim $pid | tr ' ' '|')"
		else
			ret=2 #process down
			MSG="NO execution for command $PROC_CMD (m.b. DOWN)"
		fi
	elif [[ ( "x$PROC_ID" != "x" ) ]] ; then #PROC_ID is defined
		if [[ ( -f /proc/$PROC_ID/comm ) ]] ; then
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
	local str=$(echo `printf "%02u:%02u:%02u" $hr $min $sec`)
	if [[ ($da -gt 0) ]] ; then
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
    if [ $DELIMITER ] ; then
	    ret=`grep -w $VAR $FILENAME | awk -F $DELIMITER '{print $2 $3} ' `
    else
	    ret=`grep -w $VAR $FILENAME | awk '{print $2 $3} ' `
    fi
    echo `trim "$ret"`
}

function get_measure() {
	local details="details"

	#echo "********** Validate **********"
	validate
	local ret="$?"
	if [[ ($ret -gt 1) && ($ret -lt 4) ]] ; then
	  	details="$(uri_escape \"details\":\"FATAL $MSG\")"
	    return_value="$RESP_DOWN;additionalResults:[{$details}]"
		return 1
	elif [[ ($ret -ge 4) ]] ; then
		MSG="No execution command for PID $PROC_ID or invalid parameters"
		return 16
	fi
	OIFS=$IFS
	IFS='|'
	array=( $PROC_ID )
	IFS=$OIFS
#echo "$PROC_ID array contains ${#array[@]} elements"

	local status=""
	local id=0
	local cpu=0
	local mem=0
	local virt=0
	local rss=0
	local ofd_pr=0
	local ofd=0
	local osd=0
	local threads=0
	local uptime=""
		
	for pid in ${array[@]} ; do
#		echo "processing for pid = $pid"
		details=""
		local lsof=$( lsof -p$pid )
		ofd_a=$( echo "$lsof" | wc -l )
		osd_a=$( echo "$lsof" | grep -iE "tcp | udp | ipv" | wc -l )
		local ofdm=$( ulimit -n )
		local ofd_p=$(echo "scale=1; 100 * $ofd_a / $ofdm" | bc )
	
		local FDSize=$(extract_value /proc/$pid/status FDSize :)
		FDSize=` trim "$FDSize" `
		local VmPeak=$(extract_value /proc/$pid/status VmPeak :)
		local VmSize=$(extract_value /proc/$pid/status VmSize :)
		local vartkb=$( echo $VmSize | awk '{print $1}')
		local virtmb=$(echo "scale=3; $vartkb / 1024" | bc )
		local VmHWM=$(extract_value /proc/$pid/status VmHWM :)
		local VmRSS=$(extract_value /proc/$pid/status VmRSS :)
		local rss=$( echo $VmRSS | awk '{print $1}')
		local resmb=$(echo "scale=3; $rss / 1024" | bc )
		local VmData=$(extract_value /proc/$pid/status VmData :)
		local data=$( echo $VmData | awk '{print $1}')
		local VmStk=$(extract_value /proc/$pid/status VmStk :)
		local stack=$( echo $VmStk | awk '{print $1}')
		local VmExe=$(extract_value /proc/$pid/status VmExe :)
		local Threads=$(extract_value /proc/$pid/status Threads :)
		Threads=` trim "$Threads" `

		local cm=( $( ps -p$pid -o %cpu,%mem | grep -v % ) )
		local cpu_pr=${cm[0]}
		local mem_pr=${cm[1]}
		
		local uptm=$( ps -o etime $pid | grep -v ELAPSED )
		uptm=` trim "$uptm" `
		uptm=${uptm//:/.}
		uptm=$(uri_escape "$uptm")

		#echo "*********** Analizing ****************"
		local state="OK"
		
		errors=0
		local tmp=$(( 100 * $ofd_a / $ofdm ))
		if [[ $tmp -gt 95 ]] ; then
		    MSG[$errors]="WARNING - too much open file descriptors"
		    errors=$(($errors+1))
		    state="NOK"
		fi
	
		if [[ ( ${cpu_pr/.*} -gt 95 ) || ( ${mem_pr/.*} -gt 95 ) ]] ; then
		    MSG[$errors]="WARNING - too much used resources"
		    errors=$(($errors+1))
		    state="NOK"
		fi
		
		if [ $errors -gt 0 ] ; then
		    problem="Problems detected"
		    CNT=0
		    while [[ ("$CNT" != "$errors") ]] ; do
		        problem="$problem ; ${MSG[$CNT]}"
		        CNT=$(($CNT+1))
		    done
		    details="\"details\":\"${problem}\""
		else
		    details="\"details\": \"VmPeak:$VmPeak VmHWM-$VmHWM VmData-$VmData VmStk-$VmStk\""
		    details=`uri_escape $details`
		fi
		
		if [[ ( -z $status ) ]] ; then
			id=$pid
			status=$state
			cpu=$cpu_pr
			mem=$mem_pr
			virt=$virtmb
			res=$resmb
			ofd=$ofd_a
			osd=$osd_a
			ofd_pr=$ofd_p
			threads=$Threads
			uptime=$uptm
			addata="[{$details}]"
		else
			id=$id,$pid
			status=$status,$state
			cpu=$cpu,$cpu_pr
			mem=$mem,$mem_pr
			virt=$virt,$virtmb
			res=$res,$resmb
			ofd=$ofd,$ofd_a
			osd=$osd,$osd_a
			ofd_pr=$ofd_pr,$ofd_p
			threads=$threads,$Threads
			uptime=$uptime,$uptm
			addata=$addata,"[{$details}]"
		fi
	done
	local param="status:[$status];pid:[$id];cpu:[$cpu];mem:[$mem];virt:[$virt];res:[$res];ofd:[$ofd];osd:[$osd];ofd_pr:[$ofd_pr];threads:[$threads];uptime:[$uptime];additionalResults:[$addata]"

	return_value="$param"
	return 0
}

#get_measure
#echo $return_value
