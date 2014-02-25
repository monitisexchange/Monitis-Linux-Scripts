#!/bin/bash

#
# Usage example ./stop.sh [-p <pid of process> -c <command of process>]
#

#read argument; in this case the monitoring folders paths
while getopts "p:c:" opt;
do
        case $opt in
        p) proc_id=$OPTARG ;;
        c) proc_cmd="$OPTARG" ;;
        *) echo "Wrong parameter received"
			exit 1 ;;
        esac
done


if [[ ("x$proc_cmd" != "x") ]] ; then
	pid=`ps -ef | grep -i 'monitor_start.sh' | grep -v grep | grep "$proc_cmd" | awk '{print $2} ' `
elif [[ ("x$proc_id" != "x") ]] ; then
	pid=`ps -ef | grep -i 'monitor_start.sh' | grep -v grep | grep "$proc_id" | awk '{print $2} ' `
	if [[ ($pid -ne $proc_id) ]] ; then
		echo "Specified pid ($proc_id) is wrong" >&2
		exit 1
	fi
else
	echo "All monitor_start.sh processes will be killed" >&2
	pid=`ps -efw | grep -i 'monitor_start.sh' | grep -v grep | awk '{print $2} ' `
fi

if test "$pid" ;  then
 kill -KILL $pid
 echo monitor_start.sh "$@" killed >&2
else
 echo not found monitor_start.sh "$@" >&2
fi

