#!/bin/bash

# Checking of FTP server health status
#
# usage
# ftp_check.sh --host "filegenie.com" --user "shunanya" --password "shunanya" --remote_folder "Webshared Files" --timeout <Max time [seconds] allowed for the transfer> --metrics "[action, code, size, time_total, time_connect, time_transfer, speed]" --mode {DEBUG | PLUGIN | CUSTOM} 
# ftp_check.sh -h "filegenie.com" -u "shunanya" -p "shunanya" -d "Webshared Files" -t <Max time [seconds] allowed for the transfer> --m "[action, code, size, time_total, time_connect, time_transfer, speed]" -o {DEBUG | PLUGIN | CUSTOM}
# in case when parameter contains witespace symbols this parameter should be enclosed in the quotation marks ("). 
#
# Copyright (c) 2012 Monitis-GFI 
#
# Version 0.0.5
#

declare    MAX_TIME=30	#  Default value of maximum time [seconds] allowed for the transfer
declare -r TEST_FILE="test"
declare -r MODE_DEBUG="DEBUG"
declare -r MODE_CUSTOM="CUSTOM"
declare -r MODE_PLUGIN="PLUGIN"
declare -r FAIL="FAIL"
declare    MODE="$MODE_PLUGIN" 	# DEBUG, PLUGIN, CUSTOM


while [ $# -gt 0 ]    # Until you run out of parameters . . .
do
	case $1 in
    	-h | --host | -host ) 					HOST="$2"; shift	;;
    	-u | --user | -user )  					USER="$2"; shift	;;
    	-p | --password | -password ) 			PASSWD="$2"; shift	;;
    	-d | --remote_folder | -remote_folder ) FOLDER="$2"; shift	;;
    	-m | --metrics | -metrics )				METRICS="$2"; shift ;;
    	-o | --mode | -mode )					MODE="$2"; shift 	;;
    	-t | --timeout | -timeout )				MAX_TIME="$2"; shift ;;
    	*) ;; # unknown option		
  	esac
  	shift
done

if [[ ("$MODE" == "$MODE_DEBUG") ]] ; then
	echo "**************"
	echo cmd_line:"$#" "$*"
	echo USER = "$USER" PASSWD = "$PASSWD" HOST = "$HOST" FOLDER = "$FOLDER" FILE = "$TEST_FILE" METRICS = "$METRICS"
	echo "**************"
fi

tmp=${HOST:?"Wrong or missed command line parameter"}
tmp=${USER:?"Wrong or missed command line parameter"}
tmp=${PASSWD:?"Wrong or missed command line parameter"}
tmp=${FOLDER:?"Wrong or missed command line parameter"}
tmp=${METRICS:?"Wrong or missed command line parameter"}


METRICS=${METRICS/'['/''}
METRICS=${METRICS/%']'/''}
METRICS=${METRICS//','/' '}

if [[ ("$MODE" == "$MODE_DEBUG") ]] ; then
	echo "$METRICS"
	unset metrics
	metrics=($METRICS)
	metrics_length="${#metrics[@]}"
	echo $metrics_length
fi


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

# URL status code resolving
function curlUrlCode(){
	code=$1
	case $code in	
		110) ret="110_Restart_marker_reply" ;;
		120) ret="120_Service_will_ready_later" ;;
		125) ret="125_Transfer_starting" ;;
		150) ret="150_File_status_okay" ;;
		200) ret="200_Command_OK" ;;
		202) ret="202_Command_not_implemented" ;;
		211) ret="211_System_status_reply" ;;
		212)_ret="212 Directory status"_;;
		213) ret="213_File_status" ;;
		214)_ret="214_Help_message" ;;
		215)_ret="215_system_type" ;;
		220) ret="220_Service_ready" ;;
		221)_ret="221_Closing_connection" ;;
		225)_ret="225_Connection_open" ;;
		226) ret="226_Action_OK" ;;
		227) ret="227_Entering_Passive_Mode" ;;
		230) ret="230_User_logged_in" ;;
		250) ret="250_Action_completed" ;;
		257) ret="257_PATHNAME_created" ;;
		300) ret="300_Command_will_be_executed_later" ;;
		331) ret="331_Need_password" ;;
		332) ret="332_Need_account_for_login" ;;
		350) ret="350_Pending_further_information" ;;
		400) ret="400_Command_was_not_accepted" ;;
		421) ret="421_Service_not_available" ;;
		425) ret="425_Can't_open_data_connection" ;;
		426) ret="426_Transfer_aborted" ;;
		450) ret="450_File_unavailable" ;;
		451) ret="451_Action_aborted" ;;
		452) ret="452_Insufficient_storage_space" ;;
		500) ret="500_Command_was_not_accepted" ;;
		501) ret="501_Syntax_error" ;;
		502) ret="502_Command_not_implemented" ;;
		503) ret="503_Bad_sequence_of_commands" ;;
		504) ret="504_Command_not_implemented" ;;
		530) ret="530_User_not_logged_in" ;;
		532) ret="532_Need_account_for_storing" ;;
		550) ret="550_File_unavailable" ;;
		552) ret="552_Storage_allocation_exceeded" ;;
		553) ret="553_Illegal_file_name" ;;
	esac
	echo "$ret"
}



function ftp_check(){
	# measurement units
	local action=""
	local code=""
	local size=""
	local time_total=""
	local time_connect=""
	local time_transfer=""
	local speed=""
	local details="details"
	local param=""
			
	errors=0
	#echo "list of files" 
	array_length=0
	res="$(curl -sl -m "$MAX_TIME" --user "$USER":"$PASSWD" "ftp://$HOST/$FOLDER/")"
	ret="$?"
	if [[ ( $ret -ne 0 ) ]]
	then
		descr=`curlError "$ret" `
		descr="FTPMon - list1 error $ret $descr"
		MSG[$errors]="$descr"
	    errors=$(($errors+1))
		if [[ ("$MODE" != "$MODE_CUSTOM") ]] ; then
			echo "$descr"
			return 1
		fi
	else
		unset array
		array=( $res )
		array_length1="${#array[@]}"
	fi
	
	#echo "upload file" 
	res="$(curl -s -m "$MAX_TIME" --user "$USER":"$PASSWD" -T "$TEST_FILE" "ftp://$HOST/$FOLDER/" -w "@up")"
	ret="$?"
	if [[ ( $ret -ne 0 ) ]]
	then
		descr=`curlError "$ret" `
		descr="FTPMon - upload error $ret $descr"
		MSG[$errors]="$descr"
	    errors=$(($errors+1))
		if [[ ("$MODE" != "$MODE_CUSTOM") ]] ; then
			echo "$descr"
			return 1
		else
			action="upload"
			code="$FAIL"
		fi
	else
		unset data
		data=( $res )
		data_length="${#data[@]}"
		if [[ ($data_length -eq 6) ]] ; then
			action="upload"
			code=`curlUrlCode "${data[0]}" `
			size="${data[1]}"
			time_total="${data[2]}"
			time_connect="${data[3]}"
			time_transfer="${data[4]}"
			speed="${data[5]}"
						
		fi
	fi
	
	#echo "download file"
	res="$(curl "ftp://$HOST/$FOLDER/$TEST_FILE" -s -m "$MAX_TIME" --user "$USER":"$PASSWD" -w "@down" -o /dev/null )"
	ret="$?"
	if [[ ( $ret -ne 0 ) ]]
	then
		descr=`curlError "$ret" `
		descr="FTPMon - download error $ret $descr"
		MSG[$errors]="$descr"
	    errors=$(($errors+1))
		if [[ ("$MODE" != "$MODE_CUSTOM") ]] ; then
			echo "$descr"
			return 1
		else
			action="$action","download"
			code="$code","$FAIL"
		fi
	else
		unset data
		data=( $res )
		data_length="${#data[@]}"
		if [[ ($data_length -eq 6) ]] ; then
			action="$action","download"
			tmp=`curlUrlCode "${data[0]}" `
			code="$code","$tmp"
			size="$size","${data[1]}"
			time_total="$time_total","${data[2]}"
			time_connect="$time_connect","${data[3]}"
			time_transfer="$time_transfer","${data[4]}"
			speed="$speed","${data[5]}"
						
		fi
	fi
	
	#echo "delete file"
	curl -s -m "$MAX_TIME" --user "$USER":"$PASSWD" "ftp://$HOST/" -Q "DELE /$FOLDER/$TEST_FILE" -o /dev/null
	ret="$?"
	if [[ ( $ret -ne 0 ) ]]
	then
		descr=`curlError "$ret" `
		descr="FTPMon - delete error $ret $descr"
		MSG[$errors]="$descr"
	    errors=$(($errors+1))
		if [[ ("$MODE" != "$MODE_CUSTOM") ]] ; then
			echo "$descr"
			return 1
		fi
	fi
	
	#echo "list of files"
	res="$(curl -sl -m "$MAX_TIME" --user "$USER":"$PASSWD" "ftp://$HOST/$FOLDER/")"
	ret="$?"
	if [[ ( $ret -ne 0 ) ]]
	then
		descr=`curlError "$ret" `
		descr="FTPMon - list2 error $ret $descr"
		MSG[$errors]="$descr"
	    errors=$(($errors+1))
		if [[ ("$MODE" != "$MODE_CUSTOM") ]] ; then
			echo "$descr"
			return 1
		fi
	else
		unset array
		array=( $res )
		array_length2="${#array[@]}"
		if [[ ($array_length1 -ne $array_length2) ]] ; then
			descr="FTPMon-list: count of files isn't the same - ($array_length1 <> $array_length2)"
			MSG[$errors]="$descr"
		    errors=$(($errors+1))
			if [[ ("$MODE" != "$MODE_CUSTOM") ]] ; then
				echo "$descr"
				return 1
			fi
#		else
#			echo "OK" 
		fi
	fi
	
	if [[ ("$MODE" == "$MODE_CUSTOM") ]] ; then	# whole set of action
		if [ $errors -gt 0 ]
		then
		    problem="Problems detected"
		    CNT=0
		    while [[ ("$CNT" != "$errors") ]]
		    do
		        problem="$problem + ${MSG[$CNT]}"
		        CNT=$(($CNT+1))
		    done
		    details="$details+${problem}"
		else
		    details="$details + OK"
		fi
		param="action:[$action];code:[$code];size:[$size];time_total:[$time_total];time_connect:[$time_connect];time_transfer:[$time_transfer];speed:[$speed]"
		return_value="$param | $details"	
	else
		param="" 
		for metric in $METRICS
		do
			case $metric in
				action) 		param+="action=[$action] " ;;
				code)			param+="code=[$code] " ;;
				size)			param+="size=[$size] " ;;
				time_total)		param+="time_total=[$time_total] " ;;
				time_connect)	param+="time_connect=[$time_connect] " ;;
				time_transfer)	param+="time_transfer=[$time_transfer] " ;;
				speed) 			param+="speed=[$speed] " ;;
				*) ;;
			esac
		done
		return_value="$param"	
	fi
	echo "$return_value"
	
	return 0
}

ret=` ftp_check `
res="$?"
echo "$ret"
exit "$res"

