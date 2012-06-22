#!/bin/bash


pid=`ps -efw | grep -i 'radius_monitor.sh' | grep -v grep | awk '{print $2} ' `
if test "$pid" ;  then
 kill -KILL $pid
else
 echo not found radius_monitor.sh
fi
