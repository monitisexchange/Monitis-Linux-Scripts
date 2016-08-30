#!/bin/bash

#usage: monitor_controller.sh [-d <duration in min>] [command]
#allowed commands: status (default); start; stop; restart

source monitor_constant.sh    || exit 2

cmd=-1
param="$*" #input parameters

#echo Controller: got input "$*"

if [[ ($# -gt 0) ]] ; then
  status_="status"
  stop_="stop"
  start_="start"
  restart_="restart"
  if [[ ($(expr "$param" : ".*$stop_") -gt 0) ]] ; then
      cmd=1	#stop
      echo "Command for stopping..."
  elif [[ ($(expr "$param" : ".*$restart_") -gt 0) ]] ; then
      cmd=2	#restart
      echo "Command for restarting"
  elif [[ ($(expr "$param" : ".*$start_") -gt 0) ]] ; then
  	  cmd=0 #start
  	  echo "Command for starting..."
  else
      echo "Command for status..."
  fi
fi

pid=`ps -ef | grep 'radius_monitor.sh' | grep -v grep | awk '{print $2} ' `
if [[ "$pid" ]] ; then
	echo "Monitor is running...($pid)"
	if [[ ($cmd -lt 0) ]] ; then #status
		echo "You can use 'Monitor.sh [params] [status | start | stop | restart]'"
		exit 0
	elif [[ ($cmd -eq 0) ]] ; then #start monitor
		echo "---couldn't start a new one!!!"
		exit 1
	elif [[ ($cmd -ge 1) ]] ; then #stop monitor
		echo "---stopping..."
		kill -SIGTERM $pid
		if [[ ($cmd -le 1) ]] ; then
			exit 0
		else
			sleep 5
		fi
	fi
elif [[ ($cmd -eq 1) || ($cmd -lt 0) ]] ; then
	echo "Monitor isn't running!!!"
	echo "You can use 'monitor_controller.sh [params] [status | start | stop | restart]'"
	exit 0
fi
echo "Monitor starting..."
	
# Function returns the full path to the current script.
currentscriptpath()
{
  local fullpath=`echo "$(readlink -f $0)"`
  local fullpath_length=`echo ${#fullpath}`
  local scriptname="$(basename $0)"
  local scriptname_length=`echo ${#scriptname}`
  local result_length="$(($fullpath_length - $scriptname_length - 1))"
  local result=`echo $fullpath | head -c $result_length`
  echo $result
}

PWD=` pwd `

tmp=`currentscriptpath`

cd $tmp

source $tmp/env.sh || exit 3

echo "switching to ` pwd ` and start - monitor"

echo ---------starting monitor \( "$param" \)--------------
rm temp.txt aaa.txt
$tmp/radius_monitor.sh $param & #1> /dev/null &

echo "Monitor ran with code $?" >&2

cd $PWD

exit 0

