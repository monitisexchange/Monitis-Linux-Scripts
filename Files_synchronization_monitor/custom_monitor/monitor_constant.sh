#!/bin/bash

# Declaration of monitor constants
# Server A directories for comparison (separated by './/.')
declare -r DIR_A="/opt/synctest.//./opt/synctest"
# Server B directories for comparison (separated by './/.')
declare -r DIR_B="/opt/synctest.//./opt/synctest"

declare -r HOST_A="10.137.25.64"
declare -r HOST_B="10.137.25.55"

declare -r MONITOR_NAME="from-"$HOST_A$DIR_A"-to-"$HOST_B$DIR_B  # name of custom monitor. 
declare -r MONITOR_TAG="dir_synch"			 	 # tag for custom monitor
declare -r MONITOR_TYPE="BASH_Monitor"			 # type for custom monitor
declare -r RESULT_PARAMS="monitored_files_count:monitored_files_count::2;desynch:desynch::4" # format of result params - name1:displayName1:uom1:Integer
declare -r ADDITIONAL_PARAMS="details:info::3"	 # format of additional params - name:displayName:uom:String
	
declare    DURATION=5	 							# information sending duration [min] (REPLACE by any desired value)
