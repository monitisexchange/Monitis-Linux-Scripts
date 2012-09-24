#!/bin/bash

# Declaration of global variables for Monitis Api (internally used)

declare    TOKEN=""							# obtained token value
declare -i TOKEN_OBTAIN_TIME=0				# timestamp when token was obtained
declare -ir TOKEN_EXPIRATION_TIME=$((12*60*60*1000)) 	# Token expiration time in MS (12 hours)

declare -i MONITOR_ID=0						# Registered Monitor id 

declare    MSG=""

