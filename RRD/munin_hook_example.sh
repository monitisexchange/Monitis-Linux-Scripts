#!/bin/bash

# silence!
exec >& /dev/null

# change this appropriately
declare -r MONITIS_RRD_DIR=/usr/share/monitisexchange/Monitis-Linux-Scripts/RRD

# this is usually the default
declare -r MUNIN_DIR=/var/lib/munin

main() {
	# this will update monitor 'threads' with the counter 'threads'
	# this monitor must exist prior to hooking this script on crontab
	# the monitor and counters can be easily created using:
	# cd $MONITIS_RRD_DIR && \
	#	./monitis_rrd.sh munin add_monitor $MUNIN_DIR localhost threads threads
	cd $MONITIS_RRD_DIR && \
		./monitis_rrd.sh munin update_data_for_monitor $MUNIN_DIR localhost threads threads
}

main "$@"
