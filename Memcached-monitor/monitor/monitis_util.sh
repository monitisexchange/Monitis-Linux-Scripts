#!/bin/bash

# Utility functions for Monitis Api


# Converts any unsafe or reserved characters in the path component 
# to their hexadecimal character representations (as defined in RFC3986)
# " " "!"  "#"  "$" "&" "'" "(" ")" ":"  "/"  "?"  "["  "]"  "@" "*" "+" "," ";" "="
uri_escape(){ 
	echo -E "$@" | sed 's/ /%20/g;s/!/%21/g;s/"/%22/g;s/#/%23/g;s/\$/%24/g;s/\&/%26/g;s/'\''/%27/g;s/(/%28/g;s/)/%29/g;s/:/%3A/g'
}

# Tests whether *entire string* is alphanumeric.
function isAlphaNum ()   
{
  case $1 in
  *[!a-zA-Z0-9]*|"") echo $FALSE;;
                  *) echo $TRUE;;
  esac
}

# returns the formated UTC date and time URL encoded string
# sample: 2011-08-09 09:41:44
function get_date_time() {
	date -u +"%F%%20%T"
}

# returns the formated UTC date string
# sample: 2011-08-09
function get_date() {
	date -u +"%F"
}

# returns current UTC Unix timestamp 
# (milliseconds since 00:00:00, Jan 1, 1970)
function get_timestamp() {
#	date -u +%s  # seconds since 00:00:00, Jan 1, 1970
	echo $(( `date -u +%s` * 1000 ))
}

# sample: echo "'$(trim "  one   two    three  ")'"
function trim {
    echo $*
}

# Convert json array to set of json objects separated by "|"
# @param $1 - array string to be transformed
# returns result into "response" variable
# sample:
# [{id:1},{id:2}] -> {id:1} | {id:2}
jsonArray2ss(){ 
	echo -E "$@" | sed 's/\[{/{/g;s/}\]/}/g;s/},/} \| /g;s/{/ {/g;s/})/} )/g'
}

# Tests whether *entire string* is JSON string
# @param $1 - string to be checked 
function isJSON(){
	if [[ ( "x$1" != "x" ) && ( $1 == {*} ) ]]
	then 
		return 0
	fi
	
	return 1
}

# Tests whether *entire string* is JSON array string
# @param $1 - string to be checked 
function isJSONarray(){
	local str=${1:-""}
	if [[ ( "x$str" != "x" ) && ( ${str:0:1} == "[" ) && ( ${str: -1} == "]" ) ]]
	then 
		return 0
	fi
	
	return 1
}

# Parsing JSON string and return the $prop value
# @param $1 - json input string*
# @param $2 - interesting key*
# @return picurl - interesting key value
# exit codes:
#	0 - success
#	1 - invalide input parameters
# example 
#	json=`curl -s -X GET http://twitter.com/users/show/$1.json`
#	prop='profile_image_url'
#	picurl=`jsonval $json $prop`
#
function jsonval() {
    local json=${1:-""}
    local prop=${2:-""}
    if [[ (-n $json) && (-n $prop) ]]
    then
	    temp=`echo $json | sed 's/\\\\\//\//g' | sed -e 's/[{}]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w -m1 $prop`
    	echo ${temp#*:}
    	return 0
    fi
    return 1
}

# compose additional data (JSON array) for 
#
# @param $1 - string array that contains the data to be sent
#			array[0] should contains the keyword name
# @return JSON array
function create_additional_param() {
	if [[ (-n $1) ]]
	then
		array="$1"
		if [[ (${#array[*]} -gt 0) ]]
		then
			param="["
			for (( i=1; i < $array_length; i++ ))
			do
				if [ "$i" -ne "1" ]
				then
					param=$param","
				fi
				param=$param"{\"`uri_escape ${array[0]}`\":\"`uri_escape ${array[i]}`\"}"
			done
			param=$param"]"	
			echo "$param"
		else
			echo 'Parameter (array) has no any member'
			return 4
		fi
	else 
		echo Not defined mandatory parameter
		return 4
	fi
	return 0
}

# Provides errors processing
#
# @param $1 - error code for processing 
# 			0 - code for SUCCESS (no any actions doing)
#			1 - code for WARNING (out message and return)
#			2 - code for import sources (out message and exit)
#			3 - code for error in response (out message and exit)
#			4 - code for other errors (out message and exit)
#		other - out "UNKNOWN ERROR..." and exit
# @param $2 - explanation string 
#
function error {
	case $1 in
	0)
	# succes result
		return $1
		;;
	1) 
	#warning during processing
		echo WARNING: "$2" >&2
		return $1
		;;
	2)
	# errors while import sources
		echo ERROR: The source file "$2" couldn\'t find >&2
	   ;;
	3)
	# errors in responces
		echo ERROR: The response failed..."$2" >&2
		;;
	4)
	# errors...
		echo ERROR: "$2" >&2
		;;
	*)
	# unknown error
		echo "UNKNOWN ERROR..." >&2
		;;
	esac
	exit $1
}



