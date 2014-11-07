#!/bin/bash

# Monitis Open API wrapper

# include source folders
source monitis_util.sh	   || exit 2
source monitis_global.sh   || error 2 monitis_global
source monitis_constant.sh || error 2 monitis_const

# Obtain Token from Monitis
#
# @param $1 - if true - compel of getting a new token
# otherwise token will be obtained only first time and every following 12 hours 
#
# Provides storing of TOKEN and TOKEN_OBTAIN_TIME values and returns 0 (success) return code (while success)
# returns 3 failure code in case of some errors (The existing TOKEN value will not changed in this case)
#
# sample request
# http://monitis.som/api?action=authToken&apikey=[yourAPIKey]&secretkey=[yourSecretKey]
#
function get_token() {
	local force=${1:-$FALSE}
	local val="."
	MSG=""
	
	if [[ ("$force" == "$TRUE")	 || ( ${#TOKEN} -le 0 ) \
	   || (($TOKEN_OBTAIN_TIME -ge 0) && ( $(($(get_timestamp)-$TOKEN_OBTAIN_TIME)) -gt $TOKEN_EXPIRATION_TIME ) ) ]]
	then
		local action="api?action=$API_GET_TOKEN_ACTION&apikey=$APIKEY&secretkey=$SECRETKEY&version=$APIVERSION"
		local req="$SERVER$action"
		response="$(curl -Gs $CURL_PARAMS $req)"
		local res="$?"
		if [[ ($res -eq 0) && (${#response} -gt 0) && (${#response} -lt 200) ]]	# Normally, the response text length shouldn't exceed 200 chars
		then # Likely, we received correct answer - parsing
			val=`jsonval $response $API_GET_TOKEN_ACTION `
		else
			MSG="Incorrect response while obtaining token... `curlError $res` "
			TOKEN=""
			TOKEN_OBTAIN_TIME=0
			return 1
		fi
	else
		MSG="Needless to get token this time"
		return 0
	fi
	
	if [[ "$(isAlphaNum "$val")" == "$TRUE" ]]	# token should contain an alphanumeric symbols only
	then	# correct token received - store it
		TOKEN="$val"
		TOKEN_OBTAIN_TIME=`get_timestamp`
	else
		MSG="received "$TOKEN" is WRONG"
		return 1
	fi
	return 0
}

# Returns the permanent (mandatory) paramenters for POST request
#
# apikey	{string}	public api key, which you can get from within your Monitis account(Tools->API->API Key)
# timestamp {datetime}	current datetime in GMT with yyyy-MM-dd HH:mm:ss format
# validation {string}	'token' for authToken validation
# authToken {string}	 token value that is taken via GET request 
# version	{integer}	API version(2 for current version)
# 
# parameters string is constructed by joining all the parameters together 
# and sorting them alphabetically by param name, e.g. param1value1param2value2... .
#
function get_permanent_post_param {
	local tmp=" -d apikey=$APIKEY "
		tmp=$tmp" -d timestamp=`uri_escape "$(get_date_time)"` " 
		tmp=$tmp" -d validation=$VALIDATION_METHOD "
		tmp=$tmp" -d authToken=$TOKEN "
		tmp=$tmp" -d version=$APIVERSION "
	echo $tmp
}

# Returns the permanent (mandatory) paramenters for GET request
#
# apikey	string	public api key, which you can get from within your Monitis account(Tools->API->API Key)
# output	string	the output type(available options are: XML and JSON. By default JSON is used.)
# version	integer API version(2 for current version)
# 
# parameters string is constructed by joining all the parameters together 
# and sorting them alphabetically by param name, e.g. param1value1param2value2... .
#
function get_permanent_get_param {
	local tmp=" -d apikey=$APIKEY "
		tmp=$tmp" -d output=$OUTPUT_TYPE " 
		tmp=$tmp" -d version=$APIVERSION "
	echo $tmp
}

# adds a custom monitis monitor action
# (fulfilling of POST request)
#
# Input parameters
# $1 - monitor name*
# $2 - monitor tag*
# $3 - result parameters* formatted as stated in API (name1:displayName1:uom1:dataType1[;name2:displayName2:uom2:dataType2...])
# $4 - additional result parameters formatted as stated in API (name1:displayName1:uom1:dataType1[;name2:displayName2:uom2:dataType2...])
# $5 - monitor type
# $6 - multiValue - optional value; true means that monitor can have several results for one check time.
#
# Store added monitor ID into MONITOR_ID and returns with return code 0 (success)
# (exit from application on failure)
#
# example for formatting: "thread_count:Thread count:nr:2;host:Host Address:hostaddress:3"
#
function add_custom_monitor {
	local monitor_name="$1"
	local monitor_tag="$2"
	local result_params="$3"
	local additional_params="$4"
	local monitor_type="$5"
	local multivalue="$6"
	MSG=""
	
	# check correctness of mandatory parameters
	if [[ ( -z $monitor_name) || ( -z $monitor_tag) || ( -z $result_params) ]]
	then
		MSG="Missed parameters while calling add_custom_monitor "
		return 4
	fi
	
	# POST request permanent paramenters	
	local permdata=`get_permanent_post_param`
	
	# monitor parameters
	local postdata=" -d action=$API_ADD_MONITOR_ACTION "
	postdata=$postdata" -d name=$monitor_name "
	postdata=$postdata" -d resultParams=$result_params "
#	postdata=$postdata" -d resultParams=`uri_escape "$(result_params)"` "
	postdata=$postdata" -d tag=$monitor_tag "
	if [[ (-n "$monitor_type") ]] ; then
		postdata=$postdata" -d type=$monitor_type "
	fi
	if [[ (-n "$multivalue") ]] ; then
		postdata=$postdata" -d multiValue=$multivalue "
	fi
	if [[ (-n "$additional_params") ]] ; then
		postdata=$postdata" -d additionalResultParams=$additional_params "
	fi
	
	local req="$SERVER""$API_PATH"
	
	response="$(curl -s $CURL_PARAMS $permdata $postdata	 $req)"
	local res="$?"
	if [[ ($res -eq 0) && (${#response} -gt 0) && (${#response} -lt 200) ]]	# Normally, the response text length shouldn't exceed 200 chars
	then # Likely, we received correct answer - parsing
		json="$response"
		data=""
		status=`jsonval "$json" "$RES_STATUS" `	
		error=`jsonval "$json" "$RES_ERROR" `	
		if [[ (-n "$status") ]]
		then
			if [[ (($status = "ok") || ($status = "OK")) ]]
			then
				# status is ok - checking data...
				data=`jsonval "$json" "$RES_DATA" `
			else
				if [[ (-n `echo "$status" | grep -asio -m1 "exist"`) ]]
				then
					MSG="monitor with specified parameters ( $monitor_name ; $monitor_tag ; $monitor_type ) already exists"
					return 1
				else
					MSG="add_custom_monitor: Response - $response"
					return 3
				fi
			fi
		elif [[ (-n "$error") && (-n `echo "$error" | grep -asio -m1 "exist"`) ]]
			then
					MSG="monitor with specified parameters ( $monitor_name ; $monitor_tag ; $monitor_type ) already exists"
					return 1
		else
			MSG="add_custom_monitor - $response"
			return 3
		fi	
	else
		MSG="Problem while adding monitor... `curlError $res` "
		return 3
	fi
	
	if [[ ( -z "$data") ]]
	then
		MSG="add_custom_monitor - NO RESPONSE DATA??"
		return 3
	fi	
		
	MONITOR_ID="$data"
	return 0
}

# Returns the specified custom monitor info in JSON form (if exist)
# @param $1 - monitor ID 
function get_custom_monitor_info() {
	local monitor_id=$1
	MSG=""
	
	# GET request permanent paramenters 
	local permdata=`get_permanent_get_param`
	
	# monitor parameters
	local postdata=" -d action=$API_GET_MONITOR_INFO "
	postdata=$postdata" -d monitorId=$monitor_id "
	postdata=$postdata" -d excludeHidden=true "
	
	local req="$SERVER""$API_PATH"
	
	response="$(curl -Gs $CURL_PARAMS $permdata $postdata $req)"
	local res="$?"
	if [[ ($res -eq 0) && (${#response} -gt 0) && (${#response} -lt 3000) ]] # Normally, the response text length shouldn't exceed 3000 chars
	then # Seems, we received correct answer - parsing
		 # We expect that specified monitor_id should be in the response (json)
		req="^{.*\"id\":\"$monitor_id\".*}$"
		res=`echo $response | grep -e "$req"`
		if [[ (-n "$res") ]] ; then
			MSG="$response"
		else
			MSG="Monitor with ID \"$monitor_id\" does not exist"
			return 3
		fi
	else
		if [[ (${#response} -le 0) ]]
		then
			MSG="No response received while getting monitor info... `curlError $res` "
			return 1
		else
			MSG="Response is too long while getting monitor info..."
		fi
	fi
	return 0
}

# Returns the specified custom monitors list
# @param $1 - monitor name
# @param $2 - monitor tag
# @param $3 - monitor type
#
# return result in 'response' global variables
# exit codes:
# 	0 - success
#	1 - response contain more than 1000 chars
#	3 - response contains no any monitor id
function get_monitors_list() {
	local monitor_name=${1:-""}
	local monitor_tag=${2:-""}
	local monitor_type=${3:-""}
	
	local ret=0
	
	# GET request permanent paramenters 
	local permdata=`get_permanent_get_param`
	
	# monitor parameters
	local postdata=" -d action=$API_GET_MONITOR_LIST "
	if [[ (-n "$monitor_tag") ]] ; then
		postdata=$postdata" -d tag=$monitor_tag "
	fi
	if [[ (-n "$monitor_type") ]] ; then
		postdata=$postdata" -d type=$monitor_type "
	fi
	if [[ (-n "$monitor_name") ]] ; then
		postdata=$postdata" -d name=$monitor_name "
	fi
	
	req="$SERVER""$API_PATH"
	
	response="$(curl -Gs $CURL_PARAMS $permdata $postdata $req)"
	local res="$?"
	if [[ ($res -eq 0) && (${#response} -gt 10) && (${#response} -lt 1000) ]] # Normally, the response text length shouldn't exceed 1000 chars
	then # Likely, we received correct answer
		#parsing
		isJSONarray "$response"
		ret="$?"
		if [[ ($ret -ne 0) ]] ; then # not array
				MSG="get_monitors_list - response is not an array"
				ret=3
		fi
	else
		if [[ (${#response} -le 0) ]]
		then
			MSG="get_monitors_list - No response received... `curlError $res` "
			ret=3
		else
			MSG="get_monitors_list - Unclear response..."
			ret=1
		fi
	fi	
	return $ret
}

# Returns the specified custom monitor ID (if exist)
# $1 - monitor name*
# $2 - monitor tag*
# $3 - monitor type*
function get_monitorID {
	local name=${1:-""}
	local tag=${2:-""}
	local type=${3:-""}

	local ret=0
	
    if [[ (-n $name) && (-n $tag) && (-n $type) ]] ; then
		get_monitors_list "$name" "$tag" "$type"
		ret="$?"
		if [[ ($ret -ne 0) ]] ; then
			ret=$ret
		else
			tmp=`jsonArray2ss "${response}" ` #convert json array to set of json objects separated by "|"
			set -- "$tmp" 				
				OIFS=$IFS
				IFS="|"
				declare -a Array=($*) 
				IFS=$OIFS	
			if [[ (	${#Array[@]} -eq 1 ) ]] ; then	
				value=`jsonval "${Array[0]}" "id" `
				MSG="OK"
				ret="$?"
				echo $value
				ret=$ret
			else 
				MSG="get_monitorID - Monitor not found in response list"		
			fi
		fi
	fi
	return $ret
}

# adds data for a custom monitor
#
# $1 - data for update (in the format of 'paramName1:paramValue1[;paramName2:paramValue2...]')
# $2 - Linux timestamp for record update
#
function add_custom_monitor_data() {
	local results=${1:-""}
	local timestamp=${2:-$(get_timestamp)}
	local ret=0
	MSG=""
	
	# POST request permanent paramenters	
	local permdata=`get_permanent_post_param`
	
	# ok, update the data!
	local postdata=" -d action=$API_ADD_RESULT "
	postdata=$postdata" -d monitorId=$MONITOR_ID "
	postdata=$postdata" -d checktime=$timestamp "
	postdata=$postdata" -d results=$results "
	
	req="$SERVER""$API_PATH"
	
	response="$(curl -s $CURL_PARAMS $permdata $postdata	 $req)"
	local res="$?"
	if [[ ($res -eq 0) && (${#response} -gt 0) && (${#response} -lt 200) ]] # Normally, the response text length shouldn't exceed 200 chars
	then # Likely, we received correct answer - parsing
		status=`jsonval $response $RES_STATUS `
		if [[ (-n $status) && (($status = "ok") || ($status = "OK")) ]]	# status should be OK
		then	# status is ok
			MSG="$TRUE"
		else
			MSG="add_custom_monitor_data: response - $response"
			ret=1
		fi
	else
		if [[ (${#response} -le 0) ]]
		then
			MSG="add_custom_monitor_data: No response received.. `curlError $res` "
			ret=1
		else
			MSG="add_custom_monitor_data: Response is too long..."
			ret=1
		fi
	fi
	return $ret
}

# adds additional data for a custom monitor
#
# $1 - data for update (as a JSON array: [{paramName1:paramValue1, paramName2:paramValue2, ...}, {paramName1:paramValue11, paramName2:paramValue22, ...}, ...])
# $2 - Linux timestamp for record update (should be the same value as for corresponding AddResult action)
#
function add_custom_monitor_additional_data() {
	local results=${1:-""}
	local timestamp=${2:-$(get_timestamp)}
	MSG=""
	
	# POST request permanent paramenters	
	local permdata=`get_permanent_post_param`
	
	# ok, update the data!
	local postdata=" -d action=$API_ADD_ADDITIONAL_RESULT "
	postdata=$postdata" -d monitorId=$MONITOR_ID "
	postdata=$postdata" -d checktime=$timestamp "
	postdata=$postdata" -d results=$results "
	
	req="$SERVER""$API_PATH"
	
	response="$(curl -s $CURL_PARAMS $permdata $postdata	 $req)"
	local res="$?"
	if [[ ($res -eq 0) && (${#response} -gt 0) && (${#response} -lt 200) ]]	# Normally, the response text length shouldn't exceed 200 chars
	then # Likely, we received correct answer
		#parsing
		status=`jsonval $response $RES_STATUS `
		if [[ (-n $status) && (($status = "ok") || ($status = "OK")) ]]	# status should be OK
		then	# status is ok
			MSG="$TRUE"
		else
			MSG="add_custom_monitor_additional_data. Response - $response"
			return 1
		fi
	else
		if [[ (${#response} -le 0) ]]
		then
			MSG="No response received while adding aditional data... `curlError $res` "
			return 1
		else
			MSG="Response is too long while adding aditional data..."
		fi
	fi
	return 0 
}

#Request specific parameters
#Parameter Name 	Value Type 	Value
#action * 	string 	getMonitorResults
#monitorId * 	integer 	id of the monitor to get results for
#year * 	integer 	year that results should be retrieved for
#month * 	integer 	month that results should be retrieved for
#day * 	integer 	day that results should be retrieved for
#timezone 	integer 	offset relative to GMT, used to show results in the timezone of the user

# gets data for a custom monitor
#
# $1 - date that results should be retrieved for (in form YYYY-MM-DD)
#
function get_custom_monitor_data(){
	local date=${1:-$(get_date)}
	MSG=""
	
	local year=$(echo ${date} | awk -F "-" '{print $1}' )
	local month=$(echo ${date} | awk -F "-" '{print $2}' )
	local day=$(echo ${date} | awk -F "-" '{print $3}' )
	
	# GET request permanent paramenters 
	local permdata=`get_permanent_get_param`
	
	# monitor parameters
	local postdata=" -d action=$API_GET_MONITOR_RESULTS "
	postdata=$postdata" -d monitorId=$MONITOR_ID "
	postdata=$postdata" -d year=$year "
	postdata=$postdata" -d month=$month "
	postdata=$postdata" -d day=$day "
	
	req="$SERVER""$API_PATH"
	
	response="$(curl -Gs $CURL_PARAMS $permdata $postdata $req)"
	local res="$?"
	if [[ ($res -eq 0) && (${#response} -gt 0) ]]	# Normally, the response received
	then # Likely, we received correct answer
		MSG="OK"
	else
		MSG="NO RESPONSE `curlError $res` "
		return 1
	fi
	
	return 0
}
