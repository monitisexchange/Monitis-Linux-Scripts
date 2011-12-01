#!/bin/bash

# Declaration of constants used by Monitis API

declare -r SERVER="http://www.monitis.com/"		# Monitis server
declare -r APIKEY="2PE0HVI4DHP34JACKCAE37IOD4"		# ApiKey - REPLACE it by your key's value (can be obtained from your Monitis account)
declare -r SECRETKEY="7OI90FU3C3DA8ENLNJ0JGGOGO0"	# SecretKey - REPLACE it by your key's value (can be obtained from your Monitis account)
declare -r APIVERSION="2"				# Version of existing Monitis Open API
declare -r OUTPUT_TYPE="JSON"				# Output type that is used in the current project implementation
declare -r VALIDATION_METHOD="token"			# Request validation method that is used in the current project implementation

# Declaration of Monitis API actions
declare -r API_GET_TOKEN_ACTION="authToken"		# GetToken action
declare -r API_ADD_MONITOR_ACTION="addMonitor"		# AddMonitor action
declare -r API_ADD_RESULT="addResult"			# AddResult action
declare -r API_ADD_ADDITIONAL_RESULT="addAdditionalResults"	# AddAdditionalResult action
declare -r API_GET_MONITOR_INFO="getMonitorInfo"	# GetMonitorInfo action
declare -r API_GET_MONITOR_LIST="getMonitors"		# GetMonitorsList action

# Declaration of constants that are internally used 
declare -r RES_STATUS="status"
declare -r RES_DATA="data"
declare -r DURATION=60	 				# information sending duration [sec] (REPLACE by any desired value)

declare -r TRUE=true
declare -r FALSE=false


