#!/bin/bash

# Declaration of monitor constants
declare -r MONITOR_NAME="log_monitor"					# name of custom monitor
declare -r MONITOR_TAG="logging"						# tag for custom monitor
declare -r MONITOR_TYPE="BASH_Monitor"					# type for custom monitor
declare -r RESULT_PARAMS="errors:Errors_Number::2" 		# format of result params - name1:displayName1:uom1:Integer
declare -r ADDITIONAL_PARAMS="details:Errors_detail::3"	# format of additional params - name:displayName:uom:String


declare -r LOG_FILE=~/temporary/tmp.log					# Monitored textual log file path (REPLACE by any other desired textual file)
declare -r ERR_FILE=~/temporary/errors.txt				# temporary file

# declaration of pattern-strings for finding in log file
# The string of any number of extended patterns can be defined in conform to format of "Linux grep tool"
declare -r PATTERN="error|warning|serious"

