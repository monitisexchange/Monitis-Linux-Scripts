#!/bin/bash

source monitor_constant.sh

PID=$$

rm -f $COUNT_FILE &> /dev/null

declare -a arr
for (( i=0 ; i<= "${#PATTERNS[@]}" ; i++ )) ; do
  arr[$i]=0
done	
			

# Listens for log-file changes, extracts PATTERNs defined lines
# and store them into temporary file (by adding timestamp)
tail -n0 -q -F --pid=$PID $LOG_FILE | while read line ; do
	((arr[0]++))
	echo counters "${arr[@]}"
	for (( i=1 ; i<= "${#PATTERNS[@]}" ; i++ )) ; do
        echo "$line" | grep -i -E "${PATTERNS[$(( i - 1))]}" > /dev/null
        if [[ $? -eq 0 ]] ; then
        	((arr[$i]++))
        fi					
	done
	echo "${arr[@]}" >$COUNT_FILE
done