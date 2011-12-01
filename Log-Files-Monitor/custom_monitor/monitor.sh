#!/bin/bash

source monitor_constant.sh

# Listens for log-file changes, extracts PATTERNs defined lines
# and store them into temporary file (by adding timestamp)
tail -Fn0 $LOG_FILE | while read line ; do
#        echo "$line" | grep -i -E "error|warning|SERIOUS"
        echo "$line" | grep -i -E "$PATTERN"
        if [[ $? -eq 0 ]]
        then
#                ... do something ...
			echo $(date)" - "$line >> $ERR_FILE
        fi
done