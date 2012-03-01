#!/bin/bash

# sorces included
source monitis_api.sh      || exit 2
source monitor_constant.sh || error 2 monitor_constant.sh


function get_measure() {
	local file=$RES_FILE # records file 
	local file_=$file"_" # temporary file

	#echo 'RENAMING...(for processing)'
	`mv -f "$file" "$file_" `
	local tmp=`cat $file_ `

	local input=`echo $tmp | awk -F"|" '{print $1}'`
	if [[ $input != 0 ]]; then
		input=$(echo "scale=3;($input / $DURATION)" | bc )
	fi

	out1=`echo $tmp | awk -F"|" '{print $2}'`
	out2=`echo $tmp | awk -F"|" '{print $3}'`
	ok1=`echo $tmp | awk -F"|" '{print $4}'`
	ok2=`echo $tmp | awk -F"|" '{print $5}'`
	
	if [[ $out1 != 0 ]]; then
		okPerc1=$(echo "scale=1;100*($ok1 / $out1)" | bc ) #calculate the perc. of $
        out1=$(echo "scale=3;($out1 / $DURATION)" | bc ) 
	else
		okPerc1=0
	fi

	if [[ $out2 != 0 ]]; then
		okPerc2=$(echo "scale=1;100*($ok2 / $out2)" | bc ) #calculate the perc. of $
		out2=$(echo "scale=3;($out2 / $DURATION)" | bc )
	else
		okPerc2=0
	fi

	return_value="in:$input;out1:$out1;out2:$out2;ok1:$okPerc1;ok2:$okPerc2"
	return 0
}

if [[ !( -e $LOG_FILE ) ]]
then
	error 4 "Unreachible log file $LOG_FILE"
fi

DURATION=$((60*$DURATION)) #convert to sec

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
	get_measure				# call measure function
	ret="$1"
	if [[ ($ret -ne 0) ]]
	then
	    error "$ret" "$MSG"
	    continue
	fi
	param=$return_value	# retrieve measure values
	# Compose monitor data
	echo
	echo DEBUG: Composed params is \"$param\" >&2
	echo
	timestamp=`get_timestamp`
	# Sending to Monitis
	add_custom_monitor_data $param $timestamp
	ret="$?"
	if [[ ($ret -ne 0) ]]
	then
		error "$ret" "$MSG"
		continue
	else
		echo $( date +"%D %T" ) - The Custom monitor data were successfully added
	fi
done

