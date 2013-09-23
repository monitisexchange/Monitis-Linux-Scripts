#!/bin/bash

# Utility functions for Monitis Api


# Converts any unsafe or reserved characters in the path component 
# to their hexadecimal character representations (as defined in RFC3986)
# " " "!"  "#"  "$" "&" "'" "(" ")" ":"  "/"  "?"  "["  "]"  "@" "*" "+" "," ";" "="
uri_escape(){ 
#	echo -E "$@" | sed 's/ /%20/g;s/!/%21/g;s/"/%22/g;s/#/%23/g;s/\$/%24/g;s/\&/%26/g;s/'\''/%27/g;s/(/%28/g;s/)/%29/g;s/:/%3A/g;s/\[/%5B/g;s/\]/%5D/g;s/,/%2C/g;s/;/%3B/g;s/\./%2E/g'
	echo -E "$@" | sed 's/ /%20/g;s/!/%21/g;s/"/%22/g;s/#/%23/g;s/\$/%24/g;s/\&/%26/g;s/'\''/%27/g;s/(/%28/g;s/)/%29/g;s/:/%3A/g;s/\[/%5B/g;s/\]/%5D/g;s/,/%2C/g;s/;/%3B/g'
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

#  Format a timestamp into the form 'x day hh:mm:ss'
#  @param TIMESTAMP {NUMBER} the timestamp in sec
function formatTimestamp(){
	local time="$1"
	local sec=$(( $time%60 ))
	local min=$(( ($time/60)%60 ))
	local hr=$(( ($time/3600)%24 ))
	local da=$(( $time/86400 ))
	local str=$(echo `printf "%02u.%02u.%02u" $hr $min $sec`)
	if [[ ($da -gt 0) ]]
	then
		str="$da""-""$str" 
	fi
	echo $str
}

# sample: echo "'$(trim "  one   two    three  ")'"
function trim {
    echo $*
}

#replace blanks with '_'
function replBlank {
	echo -E "$@" | tr -s '[:blank:]' '_'
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
	    local temp=`echo $json | sed 's/\\\\\//\//g' | sed -e 's/[{}]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w -m1 $prop`
	    temp="${temp#*:}"
	    if [[ (-n "$temp") ]] ; then
    		echo "$temp"
    		return 0
    	fi
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
		array=("${!1}")
		if [[ (${#array[*]} -gt 0) ]]
		then
			array_length=${#array[*]}
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

# Transforming JSON string to array (first level only)
#
# @param $1 - json string that contains the data to be transforming
# @return Strings array
function json2array(){
	local param="$1"
	local details=""
	local array
	if [[ (${#param} -gt 0) ]]
	then
		details=${param/'{'/''}
		details=${details/%'}'/''}
		details=${details//'},'/'} + '}
		details=${details//'],'/'] + '}
		details=${details//'"'/''}	
		details=${details//' '/''}
				
		param="details + $details"	
		
		unset array
		OIFS=$IFS
		IFS='+'
		array=($param)
		IFS=$OIFS	
	else
		return 1	
	fi
	echo "${array[@]}"
	return 0
}

# Replace value of given metric in the file
# @param $1 - STRING file path
# @param $2 - String metric name 
# @param $3 - String a new value to be replaced
function replaceInFile(){
	local ret=1
	if [[ ("x$1" != "x") && ("x$2" != "x") && ("x$3" != "x") ]]
	then
		local file="$1"
		local key="$2"
		local value="$3"
		if [[ (-w "$file") ]] ; then
			sed -i.bak "s/\($key *= *\).*/\1$value/" $file
			ret="$?"
		fi
			
	fi
	return $ret
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
		echo $( date +"%D %T" ) - WARNING: "$2" >&2
		return $1
		;;
	2)
	# errors while import sources
		echo $( date +"%D %T" ) - ERROR: The source file "$2" couldn\'t find >&2
	   ;;
	3)
	# errors in responces
		echo $( date +"%D %T" ) - ERROR: The response failed..."$2" >&2
		;;
	4)
	# errors...
		echo $( date +"%D %T" ) - ERROR: "$2" >&2
		;;
	10) 
	#debug during processing
		echo $( date +"%D %T" ) - DEBUG: "$2" >&2
		return 0
		;;
	*)
	# unknown error
		echo $( date +"%D %T" ) - "UNKNOWN ERROR..." >&2
		;;
	esac
	exit $1
}



