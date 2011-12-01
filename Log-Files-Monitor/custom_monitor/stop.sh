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

pid=`ps -efw | grep -i 'monitor_test.sh' | grep -v grep | awk '{print $2} ' `
if test "$pid" ;  then
 kill -KILL $pid
else
 echo not found monitor_test.sh
fi

pid=`ps -efw | grep -i xterm | grep -v grep | awk '{print $2} ' `
if test "$pid" ;  then
 kill -KILL $pid
else
 echo not found any xterm
fi
