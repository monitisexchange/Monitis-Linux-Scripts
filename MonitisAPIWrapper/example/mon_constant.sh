#!/bin/bash

# Declaration of monitor constants
declare    HOST="http://api.twitter.com/"				# API Twitter address
declare    API_VERSION=1								# Twitter API version
declare    QUERY="/users/show.json?"					# Twitter API query
declare    USER_NAME="monitis"							# Default User screen name
declare    USER_ID=17421289								# Default User ID

declare    MONITOR_NAME="Twitter:_User_"$USER_NAME"_"   # name of custom monitor
declare -r MONITOR_TAG="twitter"						# tag for custom monitor
declare -r MONITOR_TYPE="BASH_Monitor"					# type for custom monitor

# monitor commands
declare -r MON_ACTION_NAME="screen_name"
declare -r MON_ACTION_ID="user_id"
declare -r MON_GET_DATA="getData"
declare -r MON_GET_ADATA="getAData"

# format of result params - name1:displayName1:uom1:Integer
declare -r RESULT_PARAMS="status:status::3;followers_count:followers_count::2;friends_count:friends_count::2;listed_count:listed_count::2;favourites_count:favourites_count::2;statuses_count:statuses_count::2"
# format of additional params - name:displayName:uom:String
declare -r ADDITIONAL_PARAMS="details:Details::3"
declare -a additional=("id" "screen_name" "location" "url")	

declare -r NORM_STATE="OK"
declare -r FAIL_STATE="NOK"	
declare -r RESP_DOWN="status:FAIL | details + Cannot access to the Twitter"

declare    DURATION=30	 							# information sending duration [min] (REPLACE by any desired value)
