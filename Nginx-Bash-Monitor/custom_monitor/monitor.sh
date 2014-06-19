#!/bin/bash

source monitor_constant.sh || exit 2 

declare -A hash

#Remove temporary file on start of program
`rm -f $RES_FILE` > /dev/null

# Listens for log-file changes, extracts PATTERNs defined lines
# and store them into temporary file 
#temporary file format
#<count of reqs to reverse proxy>|<count of reqs to dest host 1>|<count 1xx>|<count 2xx>|<count 3xx>|<count 4xx>|<count 5xx>|<count of reqs to dest host 2>|<count 1xx>|<count 2xx>|<count 3xx>|<count 4xx>|<count 5xx>

tail -Fn0 $LOG_FILE | while read line ;  do #read line from log file
	if [[ !(-e $RES_FILE) ]] ; then # initializing
		hash[$tot]=0
		hash[$successful]=0
		hash[${dir[0]}]=0
		hash[${dir[1]}]=0
		hash["${dir[0]}""$c1xx"]=0
		hash["${dir[1]}""$c1xx"]=0
		hash["${dir[0]}""$c2xx"]=0
		hash["${dir[1]}""$c2xx"]=0
		hash["${dir[0]}""$c3xx"]=0
		hash["${dir[1]}""$c3xx"]=0
		hash["${dir[0]}""$c4xx"]=0
		hash["${dir[1]}""$c4xx"]=0
		hash["${dir[0]}""$c5xx"]=0
		hash["${dir[1]}""$c5xx"]=0
	fi
	
	hash[$tot]=$((${hash[$tot]} + 1)) #increment total number of requests. 
	for z in ${dir[@]} # for every defined ip
	do
		echo "$line" | grep -i -E "$z" > /dev/null
	    if [[ $? -eq 0 ]] ; then #check whether the line contains the specified ip
			
			hash[$z]=$((${hash[$z]}+1))  # increment the number of requests of specified ip 
			code=`echo "$line" | awk -F "#" '{print $1}'`
			if [[ (code -lt 200) ]] ; then
				hash["$z""$c1xx"]=$((${hash["$z""$c1xx"]} + 1 ))
			elif [[ (code -lt 300) ]] ; then
				hash["$z""$c2xx"]=$((${hash["$z""$c2xx"]} + 1 ))
			hash[$successful]=$((${hash[$successful]} + 1 )) #increment the total number of  successful requests
				#echo hash["$z""$c2xx"] = ${hash["$z""$c2xx"]}
			elif [[ (code -lt 400) ]] ; then
				hash["$z""$c3xx"]=$((${hash["$z""$c3xx"]} + 1 ))
			elif [[ (code -lt 500) ]] ; then
				hash["$z""$c4xx"]=$((${hash["$z""$c4xx"]} + 1 ))
			else
				hash["$z""$c5xx"]=$((${hash["$z""$c5xx"]} + 1 ))
            fi
            
		fi
	done

	tmp="${hash[$tot]}"
	tmp=$tmp"|${hash[${dir[0]}]}|${hash["${dir[0]}""$c1xx"]}|${hash["${dir[0]}""$c2xx"]}|${hash["${dir[0]}""$c3xx"]}|${hash["${dir[0]}""$c4xx"]}|${hash["${dir[0]}""$c5xx"]}"
	tmp=$tmp"|${hash[${dir[1]}]}|${hash["${dir[1]}""$c1xx"]}|${hash["${dir[1]}""$c2xx"]}|${hash["${dir[1]}""$c3xx"]}|${hash["${dir[1]}""$c4xx"]}|${hash["${dir[1]}""$c5xx"]}"

	if [[ !(-e $RES_FILE) ]]
    then # initializing
		hash[$tot]=0
		hash[$successful]=0
		hash[${dir[0]}]=0
		hash[${dir[1]}]=0
		hash["${dir[0]}""$c1xx"]=0
		hash["${dir[1]}""$c1xx"]=0
		hash["${dir[0]}""$c2xx"]=0
		hash["${dir[1]}""$c2xx"]=0
		hash["${dir[0]}""$c3xx"]=0
		hash["${dir[1]}""$c3xx"]=0
		hash["${dir[0]}""$c4xx"]=0
		hash["${dir[1]}""$c4xx"]=0
		hash["${dir[0]}""$c5xx"]=0
		hash["${dir[1]}""$c5xx"]=0
	fi
	
	echo "$tmp" > $RES_FILE #write to file
done

