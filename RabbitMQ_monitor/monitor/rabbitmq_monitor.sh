#!/bin/bash

# sorces included
source ticktick.sh			|| exit 2
source monitor_constant.sh  || exit 2

declare ret_msg
declare result

#Access to the RabbitMQ Management HTTP API, 
# execute command and keep the result in the "result" variable
#
#@param CMD {STRING} - command that should be executed
#@return error code
#
function access_rabbitmq {
	local CMD=$1
	ret_msg=""
	local url="http://$HOST:$PORT/api/$CMD"
	local response="$(curl -Gs -u "$USER":"$PSWD" $url)"
	local ret="$?"
	case $ret in
		0) ret_msg="cURL ERROR 0 - All fine. Proceed as usual" ;;
		3) ret_msg="cURL ERROR 3 - The URL was not properly formatted" ;;
		6) ret_msg="cURL ERROR 6 - Couldn't resolve host" ;;
		7) ret_msg="cURL ERROR 7 - Failed to connect to host or proxy" ;;
		9) ret_msg="cURL ERROR 9 - Access to the resource given in the URL were denied" ;;
		*) ret_msg="cURL FATAL ERROR $ret"  ;;
	esac
	if [[ ($ret -ne 0) ]] ; then
		return $ret
	elif [[ (${#response} -le 0) ]] # no answer
	then 
		ret_msg="cURL returns no any answer"
		return 100
	else # Likely, we received correct answer - parsing
		result="$response"
	fi
	return 0
}

#  Format a timestamp into the form 'x day hh:mm:ss'
#  @param TIMESTAMP {NUMBER} the timestamp in sec
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

errors=0
declare -a MSG
# get nodes info
access_rabbitmq "nodes"
ret="$?"
if [[ ($ret -ne 0) ]] ; then
	return_value="$UNAC_STATE - $ret_msg"
	echo "$return_value"
	exit 0
fi

res="{\"nodes\" : "${result}" }"
#echo "$res"

tickParse "$res"

nodes_count=1

run=``nodes[0].running``
pid=``nodes[0].os_pid``
up=``nodes[0].uptime``
upt=`formatTimestamp "$(($up / 1000))"`
ofd=``nodes[0].fd_used``
lfd=``nodes[0].fd_total``
ofdp=$(echo "scale=1;(100.0*$ofd/$lfd)" | bc )
osd=``nodes[0].sockets_used``
lsd=``nodes[0].sockets_total``
osdp=$(echo "scale=1;(100.0*$osd/$lsd)" | bc )
proc=``nodes[0].proc_used``
lproc=``nodes[0].proc_total``
procp=$(echo "scale=3;(100.0*$proc/$lproc)" | bc )
#mem=``nodes[0].mem_used``
#mem_mb=$(echo "scale=1;($mem/1024/1024)" | bc )
#lmem=``nodes[0].mem_limit``
#lmem_mb=$(echo "scale=1;($lmem/1024/1024)" | bc )
#memp=$(echo "scale=1;(100.0*$mem/$lmem)" | bc )
#dfree=``nodes[0].disk_free``
#dfree_mb=$(echo "scale=1;($dfree/1024/1024)" | bc )
#ldfree=``nodes[0].disk_free_limit``
#ldfree_mb=$(echo "scale=1;($ldfree/1024/1024)" | bc )
#dfreep=$(echo "scale=1;(100.0*$ldfree/$dfree)" | bc )

cm=( $( ps -p$pid -o %cpu,%mem | grep -v % ) )
cpu_pr=${cm[0]}
mem_pr=${cm[1]}
	
if [[ (( (${ofdp/\.*} > 90) || (${osdp/\.*} > 90) )) ]] ; then
	MSG[$errors]="WARN - Too many open files descriptors"
	errors=$(($errors+1))		
fi

if [[ (${procp/\.*} -gt 90) ]] ; then
	MSG[$errors]="WARN - Too many Erlang processes used ($proc / $lproc)"
	errors=$(($errors+1))		
fi

if [[ (${mem_pr/\.*} -gt 95) ]] ; then
	MSG[$errors]="WARN - Memory usage is critically big"
	errors=$(($errors+1))		
fi

if [[ (${cpu_pr/\.*} -gt 95) ]] ; then
	MSG[$errors]="WARN - CPU usage is critically big"
	errors=$(($errors+1))		
fi

# get overview info	
access_rabbitmq "overview"
ret="$?"
if [[ ($ret -ne 0) ]] ; then
	return_value="$UNAC_STATE" - "$ret_msg"
	echo "$return_value"
	exit 0
fi

#echo "$result"

tickParse "$result"

v=``message_stats.publish_details.rate`` ; v=${v:-0}
pub_rate=$(echo "scale=1; ($v /1)" | bc)
v=``message_stats.deliver_details.rate`` ; v=${v:-0}
delivery_rate=$(echo "scale=1; ($v /1)" | bc)
v=``message_stats.ack_details.rate`` ; v=${v:-0}
ack_rate=$(echo "scale=1; ($v /1)" | bc)
v=``message_stats.deliver_no_ack_details.rate`` ; v=${v:-0}
deliver_no_ack_rate=$(echo "scale=1; ($v /1)" | bc)
v=``message_stats.deliver_get_details.rate`` ; v=${v:-0}
deliver_get_rate=$(echo "scale=1; ($v /1)" | bc)

msg=$((``queue_total.messages``))
msg_ready=$((``queue_total.messages_ready``))
msg_unack=$((``queue_total.messages_unacknowledged``))
msg_in_queue=$(($msg + $msg_ready + $msg_unack))

if [[ ($msg_in_queue -gt 0) ]] ; then
	MSG[$errors]="WARN - some numbers of messages are left in queue"
	errors=$(($errors+1))		
fi

# get connections info
access_rabbitmq "connections"
ret="$?"
if [[ ($ret -ne 0) ]] ; then
	return_value="$UNAC_STATE" - "$ret_msg"
	echo "$return_value"
	exit 0
fi

result=${result//"basic.nack"/"basic_nack"}

res="{\"connections\" : "${result}" }"
#echo "$res"

tickParse "$res"

conn=0
r_rate=0
w_rate=0
timeout=0
l=1
while [  $l -gt 0 ] ; do
	case $conn in
		0) 	l=``connections[0].length()``
			if [[ ($l -gt 0) ]] ; then 
				conn=$((conn+1))
				r_rate=$(echo "scale=1; ``connections[0].recv_oct_details.rate`` + $r_rate" | bc)
				w_rate=$(echo "scale=1; ``connections[0].send_oct_details.rate`` + $w_rate" | bc)
				timeout=$(echo "scale=1; ``connections[0].timeout`` + $timeout" | bc) 
				client="``connections[0].client_properties.product``"_"``connections[0].client_properties.version`` (``connections[0].client_properties.platform``)"
			fi ;;
		1) 	l=``connections[1].length()``
			if [[ ($l -gt 0) ]] ; then 
				conn=$((conn+1))
				r_rate=$(echo "scale=1; ``connections[1].recv_oct_details.rate`` + $r_rate" | bc)
				w_rate=$(echo "scale=1; ``connections[1].send_oct_details.rate`` + $w_rate" | bc)
				timeout=$(echo "scale=1; ``connections[1].timeout`` + $timeout" | bc)
				client_="``connections[1].client_properties.product``"_"``connections[1].client_properties.version`` (``connections[1].client_properties.platform``)"
				if [[ ($(expr "$client" : ".*$client_") -eq 0) ]] ; then
					client="$client $client_"
				fi
			fi ;;
		2) 	l=``connections[2].length()``
			if [[ ($l -gt 0) ]] ; then 
				conn=$((conn+1))
				r_rate=$(echo "scale=1; ``connections[2].recv_oct_details.rate`` + $r_rate" | bc)
				w_rate=$(echo "scale=1; ``connections[2].send_oct_details.rate`` + $w_rate" | bc)
				timeout=$(echo "scale=1; ``connections[2].timeout`` + $timeout" | bc)
				client_="``connections[2].client_properties.product``"_"``connections[2].client_properties.version`` (``connections[2].client_properties.platform``)"
				if [[ ($(expr "$client" : ".*$client_") -eq 0) ]] ; then
					client="$client $client_"
				fi
			fi ;;
		3) 	l=``connections[3].length()``
			if [[ ($l -gt 0) ]] ; then
				conn=$((conn+1))
				r_rate=$(echo "scale=1; ``connections[3].recv_oct_details.rate`` + $r_rate" | bc)
				w_rate=$(echo "scale=1; ``connections[3].send_oct_details.rate`` + $w_rate" | bc)
				timeout=$(echo "scale=1; ``connections[3].timeout`` + $timeout" | bc)
				client_="``connections[3].client_properties.product``"_"``connections[3].client_properties.version`` (``connections[3].client_properties.platform``)"
				if [[ ($(expr "$client" : ".*$client_") -eq 0) ]] ; then
					client="$client $client_"
				fi
			fi ;;
		4) 	l=``connections[4].length()``
			if [[ ($l -gt 0) ]] ; then
				conn=$((conn+1))
				r_rate=$(echo "scale=1; ``connections[4].recv_oct_details.rate`` + $r_rate" | bc)
				w_rate=$(echo "scale=1; ``connections[4].send_oct_details.rate`` + $w_rate" | bc)
				timeout=$(echo "scale=1; ``connections[4].timeout`` + $timeout" | bc)
				client_="``connections[4].client_properties.product``"_"``connections[4].client_properties.version`` (``connections[4].client_properties.platform``)"
				if [[ ($(expr "$client" : ".*$client_") -eq 0) ]] ; then
					client="$client $client_"
				fi
			fi ;;
		5) 	l=``connections[4].length()``
			if [[ ($l -gt 0) ]] ; then
				conn=$((conn+1))
				r_rate=$(echo "scale=1; ``connections[5].recv_oct_details.rate`` + $r_rate" | bc)
				w_rate=$(echo "scale=1; ``connections[5].send_oct_details.rate`` + $w_rate" | bc)
				timeout=$(echo "scale=1; ``connections[5].timeout`` + $timeout" | bc)
				client_="``connections[5].client_properties.product``"_"``connections[5].client_properties.version`` (``connections[5].client_properties.platform``)"
				if [[ ($(expr "$client" : ".*$client_") -eq 0) ]] ; then
					client="$client $client_"
				fi
			fi ;;
		*)  l=0 ; break ;;
	esac
done		

if [[ ($conn -eq 0) ]] ; then		
	client="No any client establish connections yet"
	#MSG[$errors]="WARN - No any client establish connections yet"
	#errors=$(($errors+1))		
fi

recv_rate=$(echo "scale=1;($r_rate/1024)" | bc )
sent_rate=$(echo "scale=1;($w_rate/1024)" | bc )

details="details"
if [[ ($errors -gt 0) ]]
then
    problem="Problems in rabbitmq ($pid)"
    CNT=0
    while [ "$CNT" != "$errors" ]
    do
        problem="$problem + ${MSG[$CNT]}"
        CNT=$(($CNT+1))
    done
    details="$details+${problem}"
    status="$FAIL_STATE"
elif  [[ ($conn -eq 0) ]] ; then
    details="$details + RabbitMQ ($pid) $IDLE_STATE"
    details="$details + WARN - No any client establish connections yet"
    status="$IDLE_STATE"
else
    details="$details + RabbitMQ ($pid) $NORM_STATE"
    details="$details + $conn connections are established"
    details="$details + clients: $client"
    status="$NORM_STATE"
fi

param="status:$status;osd:$osdp;ofd:$ofdp;cpu_usage:$cpu_pr;mem_usage:$mem_pr;recv_mps:$deliver_get_rate;sent_mps:$pub_rate;msg_queue:$msg_in_queue;timeout:$timeout;recv_kbps:$recv_rate;sent_kbps:$sent_rate;uptime:$upt"
return_value="$param | $details"
echo $return_value
exit 0

