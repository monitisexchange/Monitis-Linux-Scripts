#!/bin/bash

# Utility functions for Monitis Api


# Converts any unsafe or reserved characters in the path component 
# to their hexadecimal character representations (as defined in RFC3986)
# " " "!"  "#"  "$" "&" "'" "(" ")" ":"  "/"  "?"  "["  "]"  "@" "*" "+" "," ";" "="
uri_escape(){ 
	echo -E "$@" | sed 's/%/%25/g;s/ /%20/g;s/!/%21/g;s/"/%22/g;s/#/%23/g;s/\$/%24/g;s/\&/%26/g;s/'\''/%27/g;s/(/%28/g;s/)/%29/g;s/:/%3A/g;s/\[/%5B/g;s/\]/%5D/g;s/,/%2C/g;s/;/%3B/g'
#	echo -E "$@" | sed 's/ /%20/g;s/!/%21/g;s/"/%22/g;s/#/%23/g;s/\$/%24/g;s/\&/%26/g;s/'\''/%27/g;s/(/%28/g;s/)/%29/g;s/:/%3A/g;s/\[/%5B/g;s/\]/%5D/g;s/,/%2C/g;s/;/%3B/g'
}

urlencode() {
  local string="${1}"
  local strlen=${#string}
  local encoded=""

  for (( pos=0 ; pos<strlen ; pos++ )); do
     c=${string:$pos:1}
     case "$c" in
        [-_.~a-zA-Z0-9] ) o="${c}" ;;
        * )               printf -v o '%%%02x' "'$c"
     esac
     encoded+="${o}"
  done
  echo "${encoded}"
}

# Tests whether *entire string* is alphanumeric.
function isAlphaNum ()   
{
  case $1 in
  *[!a-zA-Z0-9]*|"") echo $FALSE;;
                  *) echo $TRUE;;
  esac
}

# Checks if the first string contains the second string.
# @param $1 - entire string
# @param $2 - test string
function isContains(){
	local txt=${1:-""}
	local chk=${2:-""}
	
	if [[ (-n "$txt") && (-n "$chk") ]] ; then
		local req="^.*$chk.*$"
		res=`echo $txt | grep -e "$req"`
		if [[ (-z "$res") ]] ; then
			return 1
		fi
	else
		return 2
	fi
	return 0
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
	if [[ ( "x$str" != "x" ) && ( ${str:0:1} == "[" ) && ( ${str: -1} == "]" ) ]] ; then 
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
    if [[ (-n $json) && (-n $prop) ]] ; then
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
		array=("${@}")
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
# @return Strings separated by '+'
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
#		details=${details//' '/''}
				
		param="details + $details"	
	else
		return 1	
	fi
	echo "$param"
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

#	CURLcode resolving 
function curlError(){
	code=$1
	case $code in
		0) ret="OK";;
		1) ret="CURLE_UNSUPPORTED_PROTOCOL";;
		2) ret="CURLE_FAILED_INIT";;# Very early initialization code failed. This is likely to be an internal error or problem, or a resource problem where something fundamental couldn't get done at init time.
		3) ret="CURLE_URL_MALFORMAT";;# The URL was not properly formatted.
		4) ret="CURLE_NOT_BUILT_IN";;# A requested feature, protocol or option was not found built-in in this libcurl.
		5) ret="CURLE_COULDNT_RESOLVE_PROXY";;# Couldn't resolve proxy. The given proxy host could not be resolved.
		6) ret="CURLE_COULDNT_RESOLVE_HOST";;# Couldn't resolve host.
		7) ret="CURLE_COULDNT_CONNECT";;# Failed to connect() to host or proxy.
		8) ret="CURLE_FTP_WEIRD_SERVER_REPLY";;# After connecting to a FTP server, libcurl expects to get a certain reply back. This error code implies that it got a strange or bad reply. The given remote server is probably not an OK FTP server.
		9) ret="CURLE_REMOTE_ACCESS_DENIED";;# We were denied access to the resource given in the URL. For FTP, this occurs while trying to change to the remote directory.
		10) ret="CURLE_FTP_ACCEPT_FAILED";;# While waiting for the server to connect back when an active FTP session is used, an error code was sent over the control connection or similar.
		11) ret="CURLE_FTP_WEIRD_PASS_REPLY";;# After having sent the FTP password to the server, libcurl expects a proper reply. This error code indicates that an unexpected code was returned.
		12) ret="CURLE_FTP_ACCEPT_TIMEOUT";;# During an active FTP session while waiting for the server to connect, the CURLOPT_ACCEPTTIMOUT_MS (or the internal default) timeout expired.
		13) ret="CURLE_FTP_WEIRD_PASV_REPLY";;# libcurl failed to get a sensible result back from the server as a response to either a PASV or a EPSV command. The server is flawed.
		14) ret="CURLE_FTP_WEIRD_227_FORMAT";;# FTP servers return a 227-line as a response to a PASV command. If libcurl fails to parse that line, this return code is passed back.
		15) ret="CURLE_FTP_CANT_GET_HOST";;# An internal failure to lookup the host used for the new connection.
		17) ret="CURLE_FTP_COULDNT_SET_TYPE";;# Received an error when trying to set the transfer mode to binary or ASCII.
		18) ret="CURLE_PARTIAL_FILE";;# A file transfer was shorter or larger than expected. This happens when the server first reports an expected transfer size, and then delivers data that doesn't match the previously given size.
		19) ret="CURLE_FTP_COULDNT_RETR_FILE";;# This was either a weird reply to a 'RETR' command or a zero byte transfer complete.
		21) ret="CURLE_QUOTE_ERROR";;# When sending custom QUOTE commands to the remote server, one of the commands returned an error code that was 400 or higher (for FTP) or otherwise indicated unsuccessful completion of the command.
		22) ret="CURLE_HTTP_RETURNED_ERROR";;# This is returned if CURLOPT_FAILONERROR is set TRUE and the HTTP server returns an error code that is >= 400.
		23) ret="CURLE_WRITE_ERROR";;# An error occurred when writing received data to a local file, or an error was returned to libcurl from a write callback.
		25) ret="CURLE_UPLOAD_FAILED";;# Failed starting the upload. For FTP, the server typically denied the STOR command. The error buffer usually contains the server's explanation for this.
		26) ret="CURLE_READ_ERROR";;# There was a problem reading a local file or an error returned by the read callback.
		27) ret="CURLE_OUT_OF_MEMORY";;# A memory allocation request failed. This is serious badness and things are severely screwed up if this ever occurs.
		28) ret="CURLE_OPERATION_TIMEDOUT";;# Operation timeout. The specified time-out period was reached according to the conditions.
		30) ret="CURLE_FTP_PORT_FAILED";;# The FTP PORT command returned error. This mostly happens when you haven't specified a good enough address for libcurl to use. See CURLOPT_FTPPORT.
		31) ret="CURLE_FTP_COULDNT_USE_REST";;# The FTP REST command returned error. This should never happen if the server is sane.
		33) ret="CURLE_RANGE_ERROR";;# The server does not support or accept range requests.
		34) ret="CURLE_HTTP_POST_ERROR";;# This is an odd error that mainly occurs due to internal confusion.
		35) ret="CURLE_SSL_CONNECT_ERROR";;# A problem occurred somewhere in the SSL/TLS handshake. You really want the error buffer and read the message there as it pinpoints the problem slightly more. Could be certificates (file formats, paths, permissions), passwords, and others.
		36) ret="CURLE_BAD_DOWNLOAD_RESUME";;# The download could not be resumed because the specified offset was out of the file boundary.
		37) ret="CURLE_FILE_COULDNT_READ_FILE";;# A file given with FILE:// couldn't be opened. Most likely because the file path doesn't identify an existing file. Did you check file permissions?
		38) ret="CURLE_LDAP_CANNOT_BIND";;# LDAP cannot bind. LDAP bind operation failed.
		39) ret="CURLE_LDAP_SEARCH_FAILED";;# LDAP search failed.
		41) ret="CURLE_FUNCTION_NOT_FOUND";;# Function not found. A required zlib function was not found.
		42) ret="CURLE_ABORTED_BY_CALLBACK";;# Aborted by callback. A callback returned abort to libcurl.
		43) ret="CURLE_BAD_FUNCTION_ARGUMENT";;# Internal error. A function was called with a bad parameter.
		45) ret="CURLE_INTERFACE_FAILED";;# Interface error. A specified outgoing interface could not be used. Set which interface to use for outgoing connections' source IP address with CURLOPT_INTERFACE.
		47) ret="CURLE_TOO_MANY_REDIRECTS";;# Too many redirects. When following redirects, libcurl hit the maximum amount. Set your limit with CURLOPT_MAXREDIRS.
		48) ret="CURLE_UNKNOWN_OPTION";;# An option passed to libcurl is not recognized/known. Refer to the appropriate documentation. This is most likely a problem in the program that uses libcurl. The error buffer might contain more specific information about which exact option it concerns.
		49) ret="CURLE_TELNET_OPTION_SYNTAX";;# A telnet option string was Illegally formatted.
		51) ret="CURLE_PEER_FAILED_VERIFICATION";;# The remote server's SSL certificate or SSH md5 fingerprint was deemed not OK.
		52) ret="CURLE_GOT_NOTHING";;# Nothing was returned from the server, and under the circumstances, getting nothing is considered an error.
		53) ret="CURLE_SSL_ENGINE_NOTFOUND";;# The specified crypto engine wasn't found.
		54) ret="CURLE_SSL_ENGINE_SETFAILED";;# Failed setting the selected SSL crypto engine as default!
		55) ret="CURLE_SEND_ERROR";;# Failed sending network data.
		56) ret="CURLE_RECV_ERROR";;# Failure with receiving network data.
		58) ret="CURLE_SSL_CERTPROBLEM";;# problem with the local client certificate.
		59) ret="CURLE_SSL_CIPHER";;# Couldn't use specified cipher.
		60) ret="CURLE_SSL_CACERT";;# Peer certificate cannot be authenticated with known CA certificates.
		61) ret="CURLE_BAD_CONTENT_ENCODING";;# Unrecognized transfer encoding.
		62) ret="CURLE_LDAP_INVALID_URL";;# Invalid LDAP URL.
		63) ret="CURLE_FILESIZE_EXCEEDED";;# Maximum file size exceeded.
		64) ret="CURLE_USE_SSL_FAILED";;# Requested FTP SSL level failed.
		65) ret="CURLE_SEND_FAIL_REWIND";;# When doing a send operation curl had to rewind the data to retransmit, but the rewinding operation failed.
		66) ret="CURLE_SSL_ENGINE_INITFAILED";;# Initiating the SSL Engine failed.
		67) ret="CURLE_LOGIN_DENIED";;# The remote server denied curl to login (Added in 7.13.1)
		68) ret="CURLE_TFTP_NOTFOUND";;# File not found on TFTP server.
		69) ret="CURLE_TFTP_PERM";;# Permission problem on TFTP server.
		70) ret="CURLE_REMOTE_DISK_FULL";;# Out of disk space on the server.
		71) ret="CURLE_TFTP_ILLEGAL";;# Illegal TFTP operation.
		72) ret="CURLE_TFTP_UNKNOWNID";;# Unknown TFTP transfer ID.
		73) ret="CURLE_REMOTE_FILE_EXISTS";;# File already exists and will not be overwritten.
		74) ret="CURLE_TFTP_NOSUCHUSER";;# This error should never be returned by a properly functioning TFTP server.
		75) ret="CURLE_CONV_FAILED";;# Character conversion failed.
		76) ret="CURLE_CONV_REQD";;# Caller must register conversion callbacks.
		77) ret="CURLE_SSL_CACERT_BADFILE";;# Problem with reading the SSL CA cert (path? access rights?)
		78) ret="CURLE_REMOTE_FILE_NOT_FOUND";;# The resource referenced in the URL does not exist.
		79) ret="CURLE_SSH";;# An unspecified error occurred during the SSH session.
		80) ret="CURLE_SSL_SHUTDOWN_FAILED";;# Failed to shut down the SSL connection.
		81) ret="CURLE_AGAIN";;# Socket is not ready for send/recv wait till it's ready and try again. This return code is only returned from curl_easy_recv(3) and curl_easy_send(3) (Added in 7.18.2)
		82) ret="CURLE_SSL_CRL_BADFILE";;# Failed to load CRL file (Added in 7.19.0)
		83) ret="CURLE_SSL_ISSUER_ERROR";;# Issuer check failed (Added in 7.19.0)
		84) ret="CURLE_FTP_PRET_FAILED";;# The FTP server does not understand the PRET command at all or does not support the given argument. Be careful when using CURLOPT_CUSTOMREQUEST, a custom LIST command will be sent with PRET CMD before PASV as well. (Added in 7.20.0)
		85) ret="CURLE_RTSP_CSEQ_ERROR";;# Mismatch of RTSP CSeq numbers.
		86) ret="CURLE_RTSP_SESSION_ERROR";;# Mismatch of RTSP Session Identifiers.
		87) ret="CURLE_FTP_BAD_FILE_LIST";;# Unable to parse FTP file list (during FTP wildcard downloading).
		88) ret="CURLE_CHUNK_FAILED";;# Chunk callback reported error.
		*) ret="UNKNOWN ERROR";;# 
	esac
	echo "$ret"
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



