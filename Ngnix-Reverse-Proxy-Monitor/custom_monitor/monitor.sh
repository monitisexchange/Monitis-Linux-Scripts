#!/bin/bash

source monitor_constant.sh || exit 2 

declare -A hash

#Remove temporary file on start of program
`rm -f $RES_FILE`

# Listens for log-file changes, extracts PATTERNs defined lines
# and store them into temporary file 
#temporary file format
#<count of requests to reverse proxy server>|<count of requests to destination host 1>|<count of requests to destination host 2>|<count of requests to destination host 1 ended successfully (2xx)>|<count of requests to destination host 2 ended successfully (2xx)>

tail -Fn0 $LOG_FILE | while read line ;  #read line from lod file
do
	if [[ !(-e $RES_FILE) ]]
    then # initializing
		hash[$tot]=0
		hash[$successful]=0
		hash[${dir[0]}]=0
		hash[${dir[1]}]=0
		hash["${dir[0]}""$successful"]=0
		hash["${dir[1]}""$successful"]=0
	fi
	
	for z in ${dir[@]} # for every defined ip
	do
		echo "$line" | grep -i -E "$z" > /dev/null
    	if [[ $? -eq 0 ]]
        then #check whether the line contains the specified ip
			hash[$tot]=$((${hash[$tot]} + 1)) #increment total number of requests. 
			#Note: total means only requests from defined ips
			hash[$z]=$((${hash[$z]}+1))  # increment the number of requests of specified ip 
            echo "$line" | awk -F "#" '{print $1}' | grep -i -E "$ok" > /dev/null
			if [[ $? -eq 0 ]]
            then #whether the request passed successfuly
				hash["$z""$successful"]=$((${hash["$z""$successful"]} + 1 )) #incrament the number of successful requests of specified ip
				hash[$successful]=$((${hash[$successful]} + 1 )) #incrament the total number of  successful requests
			fi
		fi
	done
	tmp="${hash[$tot]}|${hash[${dir[0]}]}|${hash[${dir[1]}]}|${hash["${dir[0]}""$successful"]}|${hash["${dir[1]}""$successful"]}"  #compose responce
	echo "$tmp" > $RES_FILE #write to file
done

