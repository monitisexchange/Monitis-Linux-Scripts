#!/bin/bash
# Immitation of logging (for DEBUG purpose only)

source monitor_constant.sh

LINE[0]="SUPER no problem"
LINE[1]="ERROR kuku blin"
LINE[2]="Warning kak blin"
LINE[3]="SERIOUS exceptions"
LINE[4]="Normal processing"
LINE[5]="error 564jhgjhagdkjah"
LINE[6]="AAAAAAAAAAkjlkjl877879 lkkj"
LINE[7]="You could probably leave a script in cron"
LINE[8]="make sure that the script is still running"
LINE[9]="Assuming that you have GNU tail"

while [ 1 ]; do
	echo ${LINE[$RANDOM % 10]} >> "$LOG_FILE"
	sleep 10 
done

