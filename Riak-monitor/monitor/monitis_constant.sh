#!/bin/bash

# Declaration of constants used by Monitis API

declare  SERVER="http://www.monitis.com/"			# Monitis server
declare  API_PATH="customMonitorApi"				# Custom API path

declare  APIKEY="668JH8QR42O2L1EJV3KEQSU7GA"		# ApiKey - REPLACE it by your key's value (can be obtained from your Monitis account)
declare  SECRETKEY="7MER4PK0NVTNLCPND48CLBI18C"		# SecretKey - REPLACE it by your key's value (can be obtained from your Monitis account)

declare  APIVERSION="2"							# Version of existing Monitis Open API
declare  OUTPUT_TYPE="JSON"						# Output type that is used in the current project implementation
declare  VALIDATION_METHOD="token"				# Request validation method that is used in the current project implementation

# Declaration of Monitis API actions
declare  API_GET_TOKEN_ACTION="authToken"			# GetToken action
declare  API_ADD_MONITOR_ACTION="addMonitor"		# AddMonitor action
declare  API_ADD_RESULT="addResult"				# AddResult action
declare  API_ADD_ADDITIONAL_RESULT="addAdditionalResults"	# AddAdditionalResult action
declare  API_GET_MONITOR_INFO="getMonitorInfo"	# GetMonitorInfo action
declare  API_GET_MONITOR_LIST="getMonitors"		# GetMonitorsList action
declare  API_GET_MONITOR_RESULTS="getMonitorResults"	#getMonitorResults action

# Declaration of constants that are internally used 
declare  RES_STATUS="status"
declare  RES_DATA="data"

declare  TRUE=true
declare  FALSE=false


