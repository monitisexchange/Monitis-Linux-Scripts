#!/bin/bash

pid=`ps -efw | grep -i 'monitor_start.sh' | grep -v grep | awk '{print $2} ' `
if test "$pid" ;  then
 kill -KILL $pid
 echo monitor_start.sh killed
else
 echo not found monitor_start.sh
fi

