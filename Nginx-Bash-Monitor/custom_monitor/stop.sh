#!/bin/bash

pid=`ps -efw | grep -i 'monitor.sh' | grep -v grep | awk '{print $2} ' `
if test "$pid" ;  then
 kill -KILL $pid
 echo "monitor.sh is killed"
else
 echo "not found monitor.sh"
fi

pid=`ps -efw | grep -i 'monitor.log' | grep -i tail | awk '{print $2} ' `
if test "$pid" ;  then
 kill -KILL $pid
 echo "tail monitor.log is killed"
else
 echo "not found tail monitor.log"
fi

pid=`ps -efw | grep -i 'nginx_monitor.sh' | grep -v grep | awk '{print $2} ' `
if test "$pid" ;  then
 kill -KILL $pid
 echo "nginx_monitor.sh is killed"
else
 echo "not found nginx_monitor.sh"
fi
