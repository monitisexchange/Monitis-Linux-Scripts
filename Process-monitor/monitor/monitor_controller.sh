#!/bin/bash

#usage: monitor_controller.sh [-d <duration in min>] [-p <pid of process>] [-c <cmd of process>] [command]
#allowed commands: start (default); stop; restart

proc_cmd="python.*mail_manager.py"
cmd=0
param="$*" #input parameters

echo Controller: got input "$*"

if [[ ($# -gt 0) ]] ; then
  stop_="stop"
  start_="start"
  restart_="restart"
  if [[ ($(expr "$param" : ".*$stop_") -gt 0) ]] ; then
      cmd=1	#stop
  elif [[ ($(expr "$param" : ".*$restart_") -gt 0) ]] ; then
      cmd=2	#restart
  fi
fi

case $cmd in
	0) echo "Command for starting"	;;
	1) echo "Command for stopping..." ;;
	2) echo "Command for restarting" ;;
	*) echo "Unknown command" ; exit 1 ;;
esac

#read argument; in this case the monitoring folders paths
while getopts ":p:c:d:" opt;
do
        case $opt in
        p) proc_id=$OPTARG 
        	echo proc_id = $proc_id ;;
        c) proc_cmd="$OPTARG"
        	echo proc_cmd = $proc_cmd ;;
#        *) echo "Unknown parameter ignored" ;;
        esac
done

if [[ ("x$proc_cmd" != "x") ]] ; then
	pid=`ps -ef | grep -i 'monitor_start.sh' | grep -v grep | grep "$proc_cmd" | awk '{print $2} ' `
elif [[ ("x$proc_id" != "x") ]] ; then
	pid=`ps -ef | grep -i 'monitor_start.sh' | grep -v grep | grep "$proc_id" | awk '{print $2} ' `
	if [[ ($pid -ne $proc_id) ]] ; then
		echo "Specified pid ($proc_id) process isn't running" >&2
		exit 1
	fi
else
	echo "All monitor_start.sh processes will be killed" >&2
	pid=`ps -efw | grep -i 'monitor_start.sh' | grep -v grep | awk '{print $2} ' `
fi

	#	pid=`ps -efw | grep -i 'monitor_start.sh' | grep -v grep | awk '{print $2} ' `
	if [[ "$pid" ]] ; then
		echo "---Process Monitor is running with pid = $pid"
		if [[ ($cmd -eq 0) ]] ; then #start monitor
			echo "---Process Monitor is already running - couldn't start a new one!!!"
			exit 1
		elif [[ ($cmd -ge 1) ]] ; then #stop monitor
			echo "---Process Monitor stopping... ($pid)"
			kill -KILL $pid
			echo monitor_start.sh "$param" killed >&2
			if [[ ($cmd -le 1) ]] ; then
				exit 0
			else
				sleep 5
			fi
		fi
	elif [[ ($cmd -eq 1) ]] ; then
		echo "Process Monitor isn't running!!!"
		exit 0
	fi
	echo "Process Monitor starting..."
	
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

	PWD=` pwd `

	tmp=`currentscriptpath`

	cd $tmp
	echo switching to ` pwd ` and start monitor

echo ---------starting monitor \( "$param" \)--------------
	./monitor_start.sh $param 1> /dev/null &

	echo "monitor ran with status code $?" >&2

	cd $PWD

exit 0

