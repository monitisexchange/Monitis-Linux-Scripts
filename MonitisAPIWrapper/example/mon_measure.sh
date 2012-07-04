#!/bin/bash

# sorces included
source mon_constant.sh    || exit 2

declare    return_value

function get_measure() {
	local req="$HOST$API_VERSION$QUERY"
	if [[ ("x$USER_NAME" != "x") ]] ; then
		req="$req$MON_ACTION_NAME=$USER_NAME"
	elif [[ ("x$USER_ID" != "x") ]] ; then
		req="$req$MON_ACTION_ID=$USER_ID"
	fi
	local response="$(curl -Gs $req)"
	MSG="OK"
	param="status:OK"
	if [[ (${#response} -gt 0) ]]	
	then # Likely, we received correct answer
		isJSON "$response"
		ret="$?"
		if [[ ($ret -ne 0) ]]
		then
			MSG="NoJSON format in return"
			return 2
		else
			unset array
			OIFS=$IFS ; IFS=';'
			array=( $RESULT_PARAMS )
			IFS=$OIFS
			array_length="${#array[@]}"
			if [[ ($array_length -gt 0) ]] ; then
				for (( i=1 ; i < $array_length ; i++ ))
				do
					OIFS=$IFS ; IFS=':'
					array2=( ${array[$i]} )
					IFS=$OIFS
		 			value=`jsonval "$response" "${array2[0]}"`
		 			value=`uri_escape "$value" `
		 			if [[ ("x$param" == "x") ]] ; then
						param="${array2[0]}:$value"
					else
						param="$param;${array2[0]}:$value"
					fi
				done
				
			fi
			local details="details + Twitter response:"
			if [[ ("${#additional[@]}" > 0) ]] ; then
				for (( i=0 ; i < "${#additional[@]}" ; i++ ))
				do
					value=`jsonval "$response" "${additional[$i]}"`
		 			value=`uri_escape "$value" `
					details="$details + ${additional[$i]} - $value"
				done			
			fi
			return_value="$param | $details"
		fi
	else
		MSG="Incorrect Response received "
		return_value="$RESP_DOWN"
		return 1
	fi	
	return 0
}

