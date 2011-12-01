#!/bin/bash

# sorces included
source monitis_api.sh      || exit 2
source monitor_constant.sh || error 2 monitor_constant.sh
#source monitor_util.sh     || error 2 monitor_util.sh

# obtaining TOKEN
get_token
ret="$?"
if [[ ($ret -ne 0) ]]
then
	error "$ret" "$MSG"
else
	echo RECEIVE TOKEN: "$TOKEN" at "$TOKEN_OBTAIN_TIME"
	echo "All is OK for now."
fi

# Adding custom monitor
add_custom_monitor $MONITOR_NAME $MONITOR_TAG $RESULT_PARAMS $ADDITIONAL_PARAMS $MONITOR_TYPE
ret="$?"
if [[ ($ret -ne 0) ]]
then
	error "$ret" "$MSG"
else
	echo Custom monitor id = "$MONITOR_ID"
	echo "All is OK for now."
fi

if [[ ($MONITOR_ID -le 0) ]]
then 
	echo MonitorId is still zero - try to obtain it from Monitis
	
	get_custom_monitor_list $MONITOR_TAG $MONITOR_TYPE
	ret="$?"
	if [[ ($ret -ne 0) ]]
	then
		error "$ret" "$MSG"
	else
		echo Custom monitor id = "$MONITOR_ID"
		echo "All is OK for now."
	fi
fi

# Periodically adding new data
file=$ERR_FILE # errors record file 
file_=$file"_" # temporary file

while $(sleep "$DURATION")
do
	get_token			# get new token in case of the existing one is too old
	if [[ -e "$file" ]]	# log file should exist
	then
		echo 'RENAMING...(for processing)'
		mv -f "$file" "$file_"
		if [ "$?" -eq "0" ]
		then
			#read into array
			unset array
			while read line ; do
				array[${#array[@]}]="$line"
			done < $file_
			array_length="${#array[@]}"
			if [[ ($array_length -gt 0) ]]
			then
				# Compose monitor data
				param=errors:"$array_length"
				echo
				echo DEBUG: Composed params is \"$param\" >&2
				echo
				timestamp=`get_timestamp`
				# Sending to Monitis
				add_custom_monitor_data $param $timestamp
				ret="$?"
				if [[ ($ret -ne 0) ]]
				then
					error "$ret" "$MSG"
				else
					echo `date -u -d @$(( $timestamp/1000 ))` - The Custom monitor data were successfully added
					# Now create additional data
					param=`create_additional_param "${array[@]}"`
					ret="$?"
					if [[ ($ret -ne 0) ]]
					then
						error "$ret" "$param"
					else
						echo
						echo DEBUG: Composed additional params is \"$param\" >&2
						echo
						# Sending to Monitis
						add_custom_monitor_additional_data $param $timestamp
						ret="$?"
						if [[ ($ret -ne 0) ]]
						then
							error "$ret" "$MSG"
						else
							echo `date -u -d @$(( $timestamp/1000 ))` - The Custom monitor additional data were successfully added
						fi
					fi
				fi
			else
				echo ****No any interesting new records yet - sent "0" as data
				# Sending DUMMY data to Monitis 
				add_custom_monitor_data "errors:0"
				ret="$?"
				if [[ ($ret -eq 0) ]]
				then
					echo ****Succesfully added dummy data
				else
					error "$ret" "$MSG"
				fi
			fi
		else
			error 3 "Couldn't rename... "
		fi
	else
		echo ****No any new records yet contain log file \(or not exist\) - sent "0" as data
		# Sending DUMMY data to Monitis 
		add_custom_monitor_data "errors:0"
		ret="$?"
		if [[ ($ret -eq 0) ]]
		then
			echo ****Succesfully added dummy data
		else
			error "$ret" "$MSG"
		fi
	fi
done

