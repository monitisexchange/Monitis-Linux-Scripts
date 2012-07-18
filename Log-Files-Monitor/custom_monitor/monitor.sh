#!/bin/bash

source monitor_constant.sh

touch $ERR_FILE

# Listens for log-file changes, extracts PATTERNs defined lines
# and store them into temporary file (by adding timestamp)
tail -n0 -q -F $LOG_FILE | while read line ; do
        echo "$line" | grep -i -E "$PATTERN"
        if [[ $? -eq 0 ]]
        then
#                ... do something ...
			echo $(date)" - "$line >> $ERR_FILE
        fi
done