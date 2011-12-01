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
	force=${1:-$FALSE}
	local val="."
	MSG=""
	
	if [[ ("$force" == "$TRUE")	 \
	   || (($TOKEN_OBTAIN_TIME -ge 0) && ( $(($(get_timestamp)-$TOKEN_OBTAIN_TIME)) -gt $TOKEN_EXPIRATION_TIME ) ) ]]
	then
		local action="api?action=$API_GET_TOKEN_ACTION&apikey=$APIKEY&secretkey=$SECRETKEY&version=$APIVERSION"
		local req="$SERVER$action"
		local response="$(curl -Gs $req)"
		if [[ (${#response} -gt 0) && (${#response} -lt 100) ]]	# Normally, the response text length shouldn't exceed 100 chars
		then # Likely, we received correct answer
			#parsing
			local json=$response
			local prop=$API_GET_TOKEN_ACTION
			val=`jsonval`
		else
			MSG="Response is too long - perhaps received HTML response"
			return 3
		fi
	else
		MSG="Needless to get token this time"
		return 1
	fi
	
	if [[ "$(isAlphaNum "$val")" == "$TRUE" ]]	# token should contain an alphanumeric symbols only
	then	# correct token received - store it
		TOKEN="$val"
		TOKEN_OBTAIN_TIME=`get_timestamp`
	else
		MSG="received "$TOKEN" is WRONG"
		return 3
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
	postdata=$postdata" -d tag=$monitor_tag "
	if [[ (-n "$monitor_type") ]] ; then
		postdata=$postdata" -d 'type'=$monitor_type "
	fi
	if [[ (-n "$additional_params") ]] ; then
		postdata=$postdata" -d additionalResultParams=$additional_params "
	fi
	
	local req="$SERVER""customMonitorApi"
	
	response="$(curl -s $permdata $postdata	 $req)"
	
	if [[ (${#response} -gt 0) && (${#response} -lt 200) ]]	# Normally, the response text length shouldn't exceed 200 chars
	then # Likely, we received correct answer
		#parsing
		json=$response
		data=""
		prop=$RES_STATUS
		status=`jsonval`	
		if [[ (-n $status) ]]
		then
			if [[ (($status = "ok") || ($status = "OK")) ]]
			then
				# status is ok - checking data...
				prop=$RES_DATA
				data=`jsonval`
			else
				if [[ (-n `echo $status | grep -asiow -m1 "exists"`) ]]
				then
					MSG="WARNING: monitor with specified parameters already exists"
					return 1
				else
					MSG='ERROR while adding custom monitor. Response - '$response
					return 3
				fi
			fi
		else
			MSG='ERROR while adding custom monitor - NO RESPONSE STATUS??'
			return 3
		fi	
	else
		MSG="Response is too long - perhaps received HTML response"
		return 3
	fi
	
	if [[ ( -z $data) ]]
	then
		MSG='ERROR while adding custom monitor - NO RESPONSE DATA??'
		return 3
	fi	
		
	MONITOR_ID=$data
	return 0
}

# Returns the specified custom monitor info (if exist)
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
	
	req="$SERVER""customMonitorApi"
	
	response="$(curl -Gs $permdata $postdata $req)"
	
	if [[ (${#response} -gt 0) && (${#response} -lt 1000) ]] # Normally, the response text length shouldn't exceed 1000 chars
	then # Likely, we received correct answer
		#parsing
		json=$response
		prop="id"
		id=`jsonval`	
		if [[ (-n $id) && ($id -eq $monitor_id) ]]
		then
			MSG=$response
		else
			MSG="Monitor with ID \"$monitor_id\" is not exist"
			return 3
		fi
	else
		MSG="Response is too long - perhaps received HTML response"
		return 3
	fi
	return 0
}

# Returns the specified custom monitors list
# @param $1 - tag to get monitors for
# @param $2 - type of the monitor
function get_custom_monitor_list() {
	local monitor_tag=${1:-""}
	local monitor_type=${2:-""}
	MSG=""
	
	# GET request permanent paramenters 
	local permdata=`get_permanent_get_param`
	
	# monitor parameters
	local postdata=" -d action=$API_GET_MONITOR_LIST "
	if [[ (-n "$monitor_tag") ]] ; then
		postdata=$postdata" -d tag=$monitor_tag "
	fi
	if [[ (-n "$monitor_type") ]] ; then
		postdata=$postdata" -d 'type'=$monitor_type "
	fi
	
	req="$SERVER""customMonitorApi"
	
	response="$(curl -Gs $permdata $postdata $req)"
	
	if [[ (${#response} -gt 0) && (${#response} -lt 1000) ]] # Normally, the response text length shouldn't exceed 1000 chars
	then # Likely, we received correct answer
		#parsing
		json=$response
		prop="id"
		id=`jsonval`	
		if [[ (-z $id) ]]
		then
			MSG="Response contains no any ID: \"$response\""
			return 3
		fi
	else
		MSG="Response is too long - perhaps received HTML response"
		return 3
	fi
	
	MONITOR_ID=$id
	return 0
}

# adds data for a custom monitor
#
# $1 - data for update (in the format of 'paramName1:paramValue1[;paramName2:paramValue2...]')
# $2 - Linux timestamp for record update
#
function add_custom_monitor_data() {
	local results=${1:-""}
	local timestamp=${2:-$(get_timestamp)}
	MSG=""
	
	# POST request permanent paramenters	
	local permdata=`get_permanent_post_param`
	
	# ok, update the data!
	local postdata=" -d action=$API_ADD_RESULT "
	postdata=$postdata" -d monitorId=$MONITOR_ID "
	postdata=$postdata" -d checktime=$timestamp "
	postdata=$postdata" -d results=$results "
	
	req="$SERVER""customMonitorApi"
	
	response="$(curl -s $permdata $postdata	 $req)"
	
	if [[ (${#response} -gt 0) && (${#response} -lt 100) ]] # Normally, the response text length shouldn't exceed 100 chars
	then # Likely, we received correct answer
		#parsing
		json=$response
		prop=$RES_STATUS
		status=`jsonval`	
		if [[ (-n $status) && (($status = "ok") || ($status = "OK")) ]]	# status should be OK
		then	# status is ok
			MSG="$TRUE"
		else
			MSG='ERROR while adding custom monitor data. Response - '$response
			return 3
		fi
	else
		MSG="Response is too long - perhaps received HTML response"
		return 3
	fi
	return 0
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
	
	req="$SERVER""customMonitorApi"
	
	response="$(curl -s $permdata $postdata	 $req)"
	
	if [[ (${#response} -gt 0) && (${#response} -lt 100) ]]	# Normally, the response text length shouldn't exceed 100 chars
	then # Likely, we received correct answer
		#parsing
		json=$response
		prop=$RES_STATUS
		status=`jsonval`	
		if [[ (-n $status) && (($status = "ok") || ($status = "OK")) ]]	# status should be OK
		then	# status is ok
			MSG="$TRUE"
		else
			MSG='ERROR while adding custom monitor additional data. Response - '$response
			return 3
		fi
	else
		MSG="Response is too long - perhaps received HTML response"
		return 3
	fi
	return 0 
}
