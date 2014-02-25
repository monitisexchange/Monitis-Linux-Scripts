#!/bin/bash

#
# Usage example ./start.sh [-d <duration in min>] [-p <pid of process>] [-c <command of process>]
#

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
cd $tmp

echo --------try to stopping monitor \( "$*" \)--------------
./stop.sh "$@" 1> /dev/null
err="$?"
if [[ ($err -ne 0) ]] ; then
	echo "Processing is interrupted"
	exit $err
fi

echo ---------starting monitor \( "$*" \)--------------
./monitor_start.sh "$@" 1> /dev/null &


