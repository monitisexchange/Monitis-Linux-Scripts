#!/bin/bash

#usage: RmqMonitor.sh [command]
#allowed commands: start (default); stop; restart

cmd=0
param="$*" #input parameters

if [[ ($# -gt 0) ]] ; then
  stop_="stop"
  start_="start"
  restart_="restart"
  if [[ ($(expr "$param" : ".*$stop_") -gt 0) ]] ; then
      cmd=1	#stop
      echo "Command for stopping..."
  elif [[ ($(expr "$param" : ".*$restart_") -gt 0) ]] ; then
      cmd=2	#restart
      echo "Command for restarting"
  else
      echo "Command for starting"
  fi
fi

# starting Node.js monitor
pid=`ps -efw | grep -i 'rmqmon_start.sh' | grep -v grep | awk '{print $2} ' `
if [[ "$pid" ]]  
then
	echo "---RabbitMQ Monitor is running with pid = $pid"
	if [[ ($cmd -eq 0) ]] #start monitor
	then
		echo "---RabbitMQ Monitor is already running - couldn't start a new one!!!"
		exit 1
	elif [[ ($cmd -ge 1) ]] #stop monitor
	then
		echo "---RabbitMQ Monitor stopping... ($pid)"
		kill -SIGTERM $pid
		if [[ ($cmd -le 1) ]]
		then
			exit 0
		else
			sleep 5
		fi
	fi
elif [[ ($cmd -eq 1) ]]
then
	echo "RabbitMQ Monitor isn't running!!!"
	exit 0
fi
echo "RabbitMQ Monitor starting..."

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
echo switching to ` pwd ` and start - RabbitMQ monitor

./rmqmon_start.sh $param 1> /dev/null &

echo "RabbitMQ monitor ran with code $?" >&2

cd $PWD
