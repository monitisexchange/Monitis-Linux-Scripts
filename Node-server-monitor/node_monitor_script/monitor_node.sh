#!/bin/bash

# sorces included
source monitor_constant.sh    || exit 2

declare return_value

# generate access code 
#
function getAccessCode() {
	MSG=$(( `date -u +%s` / 60 ))	# curent timestamp in minutes
	echo -n $MSG | md5sum - | tr -d ' -'
	return 0
}

# Get monitor data
#
# @param $1 - string (optional) that contains the current access code
#
# @return Mesuared data
function get_measure() {
	local code=${1:-$(getAccessCode)}
	local action="$MON_ACTION=$MON_GET_DATA&$MON_ACCESS=$code"
	local req="$NODE_MONITOR$MON_PATHNAME?$action"
	local response="$(curl -Gs $req)"
	MSG="OK"
	#local details="details"
	if [[ (${#response} -gt 0) ]]	
	then # Likely, we received correct answer
		#data=$(echo ${response} | awk -F "|" '{print $1}' )
		#adata=$(echo ${response} | awk -F "|" '{print $2}' )
		#details="$details+${adata}"
		return_value="$response"
	else
		MSG="Incorrect Response received "
		problem="{\"No response reseived\":\"PERHAPS SERVER DOWN\"}"
		#details="$details+${problem}"
		return_value="$RESP_DOWN | $problem"
		return 1
	fi	
	return 0
}
