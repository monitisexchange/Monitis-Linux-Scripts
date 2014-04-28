#!/bin/bash

# sorces included
source monitor_constant.sh    || exit 2

declare return_value

# Get monitor data
#
# @return Mesuared data
function get_measure() {
	local code=$ACCESS_CODE
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
