#!/bin/bash

pid=`ps -efw | grep -i 'log_simulation.sh' | grep -v grep | awk '{print $2} ' `
if test "$pid" ;  then
 kill -KILL $pid
else
 echo not found log_simulation.sh
fi

pid=`ps -efw | grep -i 'monitor.sh' | grep -v grep | awk '{print $2} ' `
if test "$pid" ;  then
 kill -KILL $pid
else
 echo not found monitor.sh
fi

pid=`ps -efw | grep -i 'monitor.log' | grep -i tail | awk '{print $2} ' `
if test "$pid" ;  then
 kill -KILL $pid
else
 echo not found tail monitor.log
fi

pid=`ps -efw | grep -i 'nginx_monitor.sh' | grep -v grep | awk '{print $2} ' `
if test "$pid" ;  then
 kill -KILL $pid
else
 echo not found nginx_monitor.sh
fi
