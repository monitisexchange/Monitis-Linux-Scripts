#!/bin/bash
# Immitation of logging (for DEBUG purpose only)

source monitor_constant.sh || exit 2

LINE[0]="200#;195.12.12.1:80"
LINE[1]="404#;195.12.12.1:80"
LINE[2]="200#;12.13.11.12:80"
LINE[3]="404#;12.13.11.12:80"
LINE[4]="200#;195.12.12.5:80"
LINE[5]="200#;12.13.11.5:80"
LINE[6]="200#;195.12.12.1:80"
LINE[7]="200#;12.13.11.12:80"
LINE[8]="200#;195.12.12.1:80"
LINE[9]="200#;12.13.11.12:80"

while [ 1 ]; do
	echo  ${LINE[$RANDOM % 10]} >> "$LOG_FILE"
	sleep 1 
done

