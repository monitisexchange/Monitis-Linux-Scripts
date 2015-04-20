#!/bin/bash

#usage: monitor_controller.sh [command]
#allowed commands: start (default); stop; restart

cmd=0
param="$*" #input parameters

declare -a ports=(11211)
errors=0

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

for p in ${ports[@]}; do
	pid=`ps -efw | grep -i 'mmon_start.sh' | grep "$p" | awk '{print $2} ' `
	if [[ "$pid" ]] ; then
		echo "---Memcached Monitor \( $p \) is running with pid = $pid"
		if [[ ($cmd -eq 0) ]] #start monitor
		then
			echo "---Memcached Monitor \( $p \)  is already running - couldn't start a new one!!!"
			errors=$((errors++))
			continue
		elif [[ ($cmd -ge 1) ]] ; then #stop monitor
			echo "---Memcached Monitor \( $p \) stopping... ($pid)"
			kill -SIGTERM $pid
			if [[ ($cmd -le 1) ]] ; then
				continue
			else
				sleep 5
			fi
		fi
	elif [[ ($cmd -eq 1) ]] ; then
		echo "Memcached Monitor \( $p \) isn't running!!!"
		continue
	fi
	echo "Memcached Monitor \( $p \) starting..."
	
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
	echo switching to ` pwd ` and start - memcached monitors

	./mmon_start.sh -p $p $param 1> /dev/null &

	echo "Memcached monitor \( $p \) ran with status code $?" >&2

	cd $PWD
done

exit $errors

