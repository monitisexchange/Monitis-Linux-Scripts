#!/bin/bash

pid=`ps -efw | grep -i 'monitor_start.sh' | grep -v grep | awk '{print $2} ' `
if test "$pid" ;  then
 kill -KILL $pid
else
 echo not found monitor.sh
fi
