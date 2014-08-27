#!/bin/bash

pid=`ps -efw | grep -i 'nginx_monitor.sh' | grep -v grep | awk '{print $2} ' `
if test "$pid" ;  then
 kill -KILL $pid
 echo "nginx_monitor.sh is killed"
else
 echo "not found nginx_monitor.sh"
fi
