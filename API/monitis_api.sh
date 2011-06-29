#!/bin/bash

# monitis_api.sh - monitis REST API implemented in bash
# Written by Dan Fruehauf <malkodan@gmail.com>

# be careful here with spaces, quote anything with double quotes!!

# source this for keys
source monitis_config || exit 16

# some constants
declare -r API_URL="http://monitis.com/customMonitorApi"
declare -r API_ADD_MONITOR_ACTION="addMonitor"
declare -r API_ADD_RESULT_ACTION="addResult"
declare -r -i API_VERSION=2

# simply return the timestmp
_get_timestamp() {
	date -u +"%F %T"
}

# calculate the checksum for a monitis api call
# $1 - secret key
# $2 - checksum string
_calc_checksum_for_api_call() {
	local secret_key="$1"; shift
	local checksum_string="$1"; shift
	echo -en $checksum_string | openssl dgst -sha1 -hmac $secret_key -binary | openssl enc -base64
}

# adds a custom monitis monitor
# $1 - monitor name
# $2 - monitor tag
# $3 - result parameters formatted as stated in API
# example for formatting: "thread_count:Thread count:nr:2;host:Host Address:hostaddress:3"
monitis_add_custom_monitor() {
	local monitor_name="$1"; shift
	local monitor_tag="$1"; shift
	local result_params="$1"; shift
	local timestamp=`_get_timestamp`

	# these should come from monitis_config
	local api_key=$API_KEY
	local secret_key=$SECRET_KEY

	# calculate checksum
	local checksum_string="action${API_ADD_MONITOR_ACTION}apikey${api_key}name${monitor_name}resultParams${result_params}tag${monitor_tag}timestamp${timestamp}version${API_VERSION}"
	local checksum=`_calc_checksum_for_api_call $secret_key "$checksum_string"`

	# format data for posting
	local postdata="--data-urlencode \"action="$API_ADD_MONITOR_ACTION"\" --data-urlencode \"apikey="$api_key"\" --data-urlencode \"name="$monitor_name"\" --data-urlencode \"resultParams="$result_params"\" --data-urlencode \"tag="$monitor_tag"\" --data-urlencode \"timestamp=$timestamp\" --data-urlencode \"version="$API_VERSION"\" --data-urlencode \"checksum="$checksum"\""

	# invoke curl
	eval "curl ${postdata} $API_URL"
	echo
}

# updates counter data for a custom monitor
# $1 - monitor tag
# $2 - data for update (in the format of 'counter:value;counter:value')
monitis_update_custom_monitor_data() {
	local monitor_tag="$1"; shift
	local results="$1"; shift
	local xml_output_type=xml

	# these should come from monitis_config
	local api_key=$API_KEY
	local secret_key=$SECRET_KEY

	# retrieve the id for this monitor_tag
	# TODO xpath handling is far from being perfect here
	local -i monitor_id=$(curl -s "$API_URL?apikey=$api_key&output=$xml_output_type&version=$API_VERSION&action=getMonitors&tag=$monitor_tag" | xpath /monitors/monitor/id 2> /dev/null | sed -e 's#</\?id>##g')

	if [ $monitor_id -eq 0 ]; then
		echo "Could not obtain monitor id for '$monitor_tag'" 1>&2
		return 1
	fi

	# ok, update the data!
	local timestamp=`_get_timestamp`
	# TODO add the option to pass a different time other than UTC
	local check_time=`date -u +"%s"000`
	local checksum_string="action${API_ADD_RESULT_ACTION}apikey${api_key}checktime${check_time}monitorId${monitor_id}results${results}timestamp${timestamp}version${API_VERSION}"
	local checksum=`_calc_checksum_for_api_call $secret_key "$checksum_string"`

	# invoke curl
	local postdata="--data-urlencode \"action="$API_ADD_RESULT_ACTION"\" --data-urlencode \"apikey="$api_key"\" --data-urlencode \"checktime="$check_time"\" --data-urlencode \"monitorId="$monitor_id"\" --data-urlencode \"results="$results"\" --data-urlencode \"timestamp=$timestamp\" --data-urlencode \"version="$API_VERSION"\" --data-urlencode \"checksum="$checksum"\""
	eval "curl ${postdata} $API_URL"
	echo
}
