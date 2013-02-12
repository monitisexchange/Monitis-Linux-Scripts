#!/bin/bash

source monitor_constant.sh

# Function returns the full path to the current script.
currentscriptpath()
{
  local fullpath=`echo "$(readlink -f $0)"`
  local fullpath_length=`echo ${#fullpath}`
  local scriptname="$(basename $0)"
  local scriptname_length=`echo ${#scriptname}`
  local result_length=`echo $fullpath_length - $scriptname_length - 1 | bc`
  local result=`echo $fullpath | head -c $result_length`
  echo $result
}

tmp=`currentscriptpath`
cd "$tmp"

./stop.sh 1> /dev/null

echo ---------starting test loop--------------
xterm -hold -sb -e ./log_simulation.sh "$ERR_FILE" &
xterm -hold -sb -e ./monitor.sh "$ERR_FILE" &
xterm -hold -sb -e ./monitor_test.sh "$@" "$ERR_FILE" &
