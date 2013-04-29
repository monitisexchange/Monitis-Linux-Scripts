#!/bin/bash
# Immitation of logging (for DEBUG purpose only)

source monitor_constant.sh

LINE[0]="SUPER no problem"
LINE[1]="kuku blin"
LINE[2]="Warning kak blin"
LINE[3]="SERIOUS exceptions kuku"
LINE[4]="Send IM to blin"
LINE[5]="error blin 564jhgjhagdkjah"
LINE[6]="Send mail to kuku"
LINE[7]="WARNING: You could probably leave a script in cron"
LINE[8]="make sure that the script is still running"
LINE[9]="Assuming that you have GNU tail and service is running"

while [ 1 ]; do
	echo ${LINE[$RANDOM % 10]} | tee -a "$LOG_FILE"
	sleep 1
done

