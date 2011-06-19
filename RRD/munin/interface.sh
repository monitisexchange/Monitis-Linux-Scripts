#!/bin/bash

# munin/interface.sh - an integration of munin and monitis
# Written by Dan Fruehauf <malkodan@gmail.com>

# this will usually not change
#declare -r MUNIN_DIR=/var/lib/munin

############################################
############# PUBLIC INTERFACE #############
############################################

# list all monitors
# $1 - munin directory
# $2 - hostname
list_monitors() {
	local munin_dir=$1; shift
	local hostname=$1; shift
	local monitor
	ls -1 $munin_dir/$hostname/$hostname-* | cut -d'-' -f2 | sort | uniq
}

# returns the counters a monitor supports
# $1 - munin directory
# $2 - hostname
# $3 - monitor name
list_counters_for_monitor() {
	local munin_dir=$1; shift
	local hostname=$1; shift
	local monitor_name=$1; shift
	(cd $munin_dir/$hostname && ls -1 $hostname-$monitor_name-* | cut -d'-' -f3) 2> /dev/null
}

# add a single monitor with description and appropriate counters
# $1 - munin directory
# $2 - hostname
# $3 - monitor name
# $@ - counters to add, or 'ALL' if you want to add them all
add_monitor() {
	local munin_dir=$1; shift
	local hostname=$1; shift
	local monitor_name=$1; shift
	# add all counters if user wants it...
	local counters="$@"
	if [ x"$counters" != x ]; then
		echo "No counters specified, use 'ALL' to add them all" 1>&2
		return 1
	elif [ "$counters" == "ALL" ]; then
		local counters=`list_counters_for_monitor $munin_dir $hostname $monitor_name | xargs`
	else
		# if user specified them, make sure they actually exist
		if ! _validate_counters $munin_dir $hostname $monitor_name $counters; then
			echo "Some counters specified are invalid, aborting" 1>&2
			return 1
		fi
	fi

	if [ x"$counters" = x ]; then
		echo "No counters found for monitor '$monitor_name'"
		return 1
	fi
	echo "Adding $monitor_name for $hostname with counters '$counters'"

	# get description and UOM
	local monitor_description=`_get_monitor_description $munin_dir $hostname $monitor_name`
	local monitor_uom=`_get_monitor_uom $munin_dir $hostname $monitor_name`

	# format result parameters for monitis
	local counter
	for counter in $counters; do
		local counter_name=$counter
		local counter_display_name=$counter
		local counter_uom=$monitor_uom
		# TODO it's always integer (2)
		local -i counter_datatype=2
		local result_params="$result_params;$counter_name:$counter_display_name:$counter_uom:$counter_datatype"
	done
	# remove first ';' as it is unneeded
	result_params=${result_params:1}

	echo "Monitor description will be '$monitor_description'"
	echo "Monitor UOM will be '$monitor_uom'"
	echo "Monitor result_params will be '$result_params'"
	local monitor_tag=`_canonize_monitor_tag_from_name $hostname $MONITIS_TAG_PREFIX $monitor_name`

	# add the monitor calling monitis api
	monitis_add_custom_monitor $API_KEY $SECRET_KEY $monitor_name $monitor_tag "$result_params"
}

# returns data for monitor by querying every counter
# $1 - munin directory
# $2 - hostname
# $3 - monitor name
# $@ - counters to update, or ALL if you want to add them all
update_data_for_monitor() {
	local munin_dir=$1; shift
	local hostname=$1; shift
	local monitor_name=$1; shift
	local monitor_tag=`_canonize_monitor_tag_from_name $hostname $MONITIS_TAG_PREFIX $monitor_name`
	local counters="$@"
	if [ x"$counters" != x -a "$counters" == "ALL" ]; then
		local counters=`list_counters_for_monitor $munin_dir $hostname $monitor_name | xargs`
	else
		# if user specified them, make sure they actually exist
		if ! _validate_counters $munin_dir $hostname $monitor_name $counters; then
			echo "Some counters specified are invalid, aborting" 1>&2
			return 1
		fi
	fi

	# get the data
	for counter in $counters; do
		local data=`_get_last_data_for_counter $munin_dir $hostname $monitor_name $counter`
		data_for_update="$data_for_update;$counter:$data"
	done
	# remove first ';' as it is unneeded
	data_for_update=${data_for_update:1}

	# call monitis api to update data
	monitis_update_custom_monitor_data $API_KEY $SECRET_KEY $monitor_tag "$data_for_update"
}

############################################
############# PRIVATE METHODS ##############
############################################

# TODO some end in g.rrd, c.rrd and d.rrd - find out the meaning of it
declare -r MUNIN_RRD_SUFFIX=".rrd"

# this is the tag prefix in monitis
declare -r MONITIS_TAG_PREFIX="munin"

# TODO this is unused, it'll add all monitors with all counters
# adds all custom monitors for a given hostname
# $1 - munin directory
# $2 - hostname
add_monitors() {
	local munin_dir=$1; shift
	local hostname=$1; shift
	local monitor
	for monitor in `ls -1 $munin_dir/$hostname/$hostname-* | cut -d'-' -f2 | sort | uniq`; do
		add_munin_custom_monitor $munin_dir $hostname $monitor
	done
}

# if user specified them, make sure they actually exist
# $@ - counters to validate
# returns true if all counters are valid
_validate_counters() {
	local munin_dir=$1; shift
	local hostname=$1; shift
	local monitor_name=$1; shift
	local -i retval=0
	for counter in "$@"; do
		if ! [ -f $munin_dir/$hostname/$hostname-$monitor_name-$counter-*$MUNIN_RRD_SUFFIX ]; then
			echo "'$counter' is an invalid counter" 1>&2
			let retval=$retval+1
		fi
	done
	return $retval
	local counters
}

# returns the description of a monitor
# $1 - munin directory
# $2 - hostname
# $3 - monitor name
_get_monitor_description() {
	local munin_dir=$1; shift
	local hostname=$1; shift
	local monitor_name=$1; shift
	grep "$hostname;$hostname:$monitor_name\.graph_title" $munin_dir/datafile | cut -d' ' -f2-
}

# returns the UOM (unit of measurement) of a monitor
# $1 - munin directory
# $2 - hostname
# $3 - monitor name
_get_monitor_uom() {
	local munin_dir=$1; shift
	local hostname=$1; shift
	local monitor_name=$1; shift
	grep "$hostname;$hostname:$monitor_name\.graph_vlabel" $munin_dir/datafile | cut -d' ' -f2-
}


# returns last data in monitor using 'rrdtool lastupdate'
# $1 - munin directory
# $2 - hostname
# $3 - monitor name
_get_last_data_for_counter() {
	local munin_dir=$1; shift
	local hostname=$1; shift
	local monitor_name=$1; shift
	local counter=$1; shift
	rrdtool lastupdate $munin_dir/$hostname/$hostname-$monitor_name-$counter-*$MUNIN_RRD_SUFFIX | tail -1 | cut -d' ' -f2
}
