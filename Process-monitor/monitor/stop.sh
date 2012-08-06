#!/bin/bash

#
# Usage example ./stop.sh [<process command>]
#

if [[ ($# -gt 0) && ("x$1" != "x") ]]
then
	pid=`ps -efw | grep -i 'monitor_start.sh' | grep -v grep | grep "$1" | awk '{print $2} ' `
else
	pid=`ps -efw | grep -i 'monitor_start.sh' | grep -v grep | awk '{print $2} ' `
fi

if test "$pid" ;  then
 kill -KILL $pid
 echo monitor_start.sh "$1" killed
else
 echo not found monitor_start.sh "$1"
fi

