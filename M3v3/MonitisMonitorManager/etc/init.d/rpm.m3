#!/bin/bash
#
# M3              This shell script takes care of starting and stopping
#                 M3 (Monitis Monitor Manager).
#
# chkconfig: - 13 87
# description: M3 is used for monitoring and integration with
# Monitis (http://www.monitis.com)
# probe: true

### BEGIN INIT INFO
# Provides: $M3
# Required-Start: $local_fs $network $syslog
# Required-Stop: $local_fs $network $syslog
# Default-Start: 3 4 5
# Default-Stop: 0 1 2 6
# Short-Description: start|stop|status|restart|configtest M3
# Description: control M3 (Monitis Monitor Manager)
### END INIT INFO

# Source function library.
. /etc/rc.d/init.d/functions

[ -r /etc/sysconfig/m3 ] && . /etc/sysconfig/m3

m3=/usr/bin/monitis-m3

RETVAL=0

pidofm3() {
	pidofproc "$m3";
}

# start m3 if not started already
start()
{
	echo -n "Starting m3:"
	export M3_CONFIG_DIR
	if ! status >& /dev/null; then
		# check if M3_CONFIG_XML is defined
		if [ x"$M3_CONFIG_XML" = x ]; then
			echo -n " M3_CONFIG_XML undefined in /etc/sysconfig/m3"
			failure; echo
			return 1
		fi

		$m3 --syslog $M3_CONFIG_XML &
		success; echo
	else
		echo -n " already running!"
		failure; echo
	fi
}

# stop m3 instances
stop() {
	echo -n "Stopping m3:"
	for i in `seq 1 10`; do
		local m3_pids=`pidofm3`
		if [ x"$m3_pids" != x ]; then
			kill -SIGINT $m3_pids
		else
			success; echo
			return 0
		fi
		sleep 1
	done
	failure; echo
}

# return the status of the M3 instances
status() {
	local m3_pids=`pidofm3`
	if [ x"$m3_pids" != x ]; then
		echo "m3 is running: $m3_pids"
		return 0
	else
		echo "m3 is NOT running."
		return 1
	fi
}

# restart- stop, then start
restart() {
	stop
	start
}	

# return true if configuration is OK
checkconfig() {
	xmlwf_output=`xmlwf $M3_CONFIG_XML`
	if [ x"$xmlwf_output" != x ]; then
		echo $xmlwf_output
		return 2
	fi
	# if the XML test passed, try this
	$m3 --test-config $M3_CONFIG_XML
}

# See how we were called.
case "$1" in
	start)
		start
		;;
	stop)
		stop
		;;
	status)
		status
		RETVAL=$?
		;;
	restart)
		restart
		;;
	checkconfig|configtest|check|test)
		checkconfig
		;;
	*)
		echo $"Usage: $0 {start|stop|status|restart|configtest}"
		[ "x$1" = "x" ] && exit 0
		exit 2
esac

exit $RETVAL

