#!/bin/bash
# sorces included
source monitis_api.sh        || exit 2
source monitor_constant.sh || error 2 monitor_constant.sh

declare -A hash1
declare -A hash2

DURATION=$((60*$DURATION)) #convert to sec


scp dir_synch.sh $HOST_A":~/" #copy script to remote host
scp dir_synch.sh $HOST_B":~/" #copy script to remote host

# this function stors the files and corresponding checksums in hash map
function stringToHash(){
  a=$1
  b=$2

  ary=($(echo $1 | sed -e 's/\/\//\n/g' | while read line; do echo $line | sed 's/[\t ]/\/\//g'; done))

  for (( dd = 0; dd < ${#ary[@]}; dd++ ))
  do
     ary[dd]=$(echo ${ary[dd]} | sed 's/\/\// /g')
     key=`echo ${ary[dd]} | awk -F"/" '{print $1}'`
     value=`echo ${ary[dd]} | awk -F"/" '{print $2}'`
     if [[ $b == 1 ]]
     then
       hash1[$key]=$value
     elif [[ $b == 2 ]]
     then
       hash2[$key]=$value
     fi
  done
  unset ary
}


function getMeasure() {

	str1=$(ssh $HOST_A "bash ~/dir_synch.sh -d '$DIR_A'")
	str2=$(ssh $HOST_B "bash ~/dir_synch.sh -d '$DIR_B'")
	
	count=0
	total=0
	
	#store the results from specified host A in array, where each element represents results from one directory
	sList1=($(echo $str1 | sed -e 's/\/\/\//\n/g' | while read line; do echo $line | sed 's/[\t ]/\/\/\//g'; done))
	
	for (( w = 0; w < ${#sList1[@]}; w++ ))
	do
	  sList1[w]=$(echo ${sList1[w]} | sed 's/\/\/\// /g')
	done
	
	#store the results from specified host B in array, where each element represents results from one directory
	sList2=($(echo $str2 | sed -e 's/\/\/\//\n/g' | while read line; do echo $line | sed 's/[\t ]/\/\/\//g'; done))
	
	for (( f = 0; f < ${#sList2[@]}; f++ ))
	do
	  sList2[f]=$(echo ${sList2[f]} | sed 's/\/\/\// /g')
	done
	
	#compare file and checksums
	for (( p = 0; p < ${#sList1[@]}; p++ ))
	do
	  stringToHash "${sList1[p]}" 1
	  stringToHash "${sList2[p]}" 2
	  total=$(( $total + ${#hash1[@]} ))
	  for v in "${!hash1[@]}"
	  do
	    if [[ ${hash1[$v] } != ${hash2[$v] } ]]; then
	      count=$(( $count + 1 ))
	    fi
	  done
	done
	  
	unset hash1
	unset hash2
	
	if [[ $count != 0 ]]
	then
	  count=$(echo "scale=3;100*($count / $total)" | bc ) #calculate the perc. of $
	fi
	
	echo "monitored_files_count:$total;desynch:$count"
	
	unset hash1
	unset hash2
}

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
add_custom_monitor $MONITOR_NAME $MONITOR_TAG $RESULT_PARAMS $ADDITIONAL_PARAMS $MONITOR_TYPE
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
	
	MONITOR_ID=`get_monitorID $MONITOR_NAME $MONITOR_TAG $MONITOR_TYPE `
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
	ret="$1"
	if [[ ($ret -ne 0) ]]
	then	# some problems while getting token...
		error "$ret" "$MSG"
		continue
	fi

	param=`getMeasure`
	echo
	echo DEBUG: Composed params is \"$param\" >&2
	echo
	timestamp=`get_timestamp`
	# Sending to Monitis
	add_custom_monitor_data $param $timestamp
done
