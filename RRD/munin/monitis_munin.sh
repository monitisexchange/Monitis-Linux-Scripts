#!/bin/bash

# Written by Dan Fruehauf <malkodan@gmail.com>

# source this for monitis functions
source monitis_interface.sh || exit 16

# this will usually not change
declare -r MUNIN_DIR=/var/lib/munin

# canonize the monitor name, so it's standard
# essentially we'll just add a 'munin_' prefix
# $1 - monitor name
_canonize_monitor_tag_from_name() {
	local monitor_name=$1; shift
	echo "munin_$monitor_name"
}

# add a single monitor with description and appropriate counters
# $1 - munin directory
# $2 - hostname
# $3 - monitor name
add_munin_custom_monitor() {
	local munin_dir=$1; shift
	local hostname=$1; shift
	local monitor_name=$1; shift
	local counters=`get_counters_for_monitor $munin_dir $hostname $monitor_name | xargs`
	echo "Adding $monitor_name for $hostname with counters '$counters'"

	# get description and UOM
	local monitor_description=`get_monitor_description $munin_dir $hostname $monitor_name`
	local monitor_uom=`get_monitor_uom $munin_dir $hostname $monitor_name`

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
	local monitor_tag=`_canonize_monitor_tag_from_name $monitor_name`

	# add the monitor calling monitis api
	monitis_add_custom_monitor $API_KEY $SECRET_KEY $monitor_name $monitor_tag "$result_params"
}

# adds all custom monitors for a given hostname
# $1 - munin directory
# $2 - hostname
add_munin_custom_monitors() {
	local munin_dir=$1; shift
	local hostname=$1; shift
	local monitor
	for monitor in `ls -1 $munin_dir/$hostname/$hostname-* | cut -d'-' -f2 | sort | uniq`; do
		add_munin_custom_monitor $munin_dir $hostname $monitor
	done
}

# returns the counters a monitor supports
# $1 - munin directory
# $2 - hostname
# $3 - monitor name
get_counters_for_monitor() {
	local munin_dir=$1; shift
	local hostname=$1; shift
	local monitor_name=$1; shift
	(cd $munin_dir/$hostname && ls -1 $hostname-$monitor_name-* | cut -d'-' -f3 | xargs)
}

# returns the description of a monitor
# $1 - munin directory
# $2 - hostname
# $3 - monitor name
get_monitor_description() {
	local munin_dir=$1; shift
	local hostname=$1; shift
	local monitor_name=$1; shift
	grep "$hostname;$hostname:$monitor_name\.graph_title" $munin_dir/datafile | cut -d' ' -f2-
}

# returns the UOM (unit of measurement) of a monitor
# $1 - munin directory
# $2 - hostname
# $3 - monitor name
get_monitor_uom() {
	local munin_dir=$1; shift
	local hostname=$1; shift
	local monitor_name=$1; shift
	grep "$hostname;$hostname:$monitor_name\.graph_vlabel" $munin_dir/datafile | cut -d' ' -f2-
}

# returns data for monitor by querying every counter
# $1 - munin directory
# $2 - hostname
# $3 - monitor name
get_data_for_monitor() {
	local munin_dir=$1; shift
	local hostname=$1; shift
	local monitor_name=$1; shift
	local monitor_tag=`_canonize_monitor_tag_from_name $monitor_name`
	local counters=`cd $munin_dir/$hostname && ls -1 $hostname-$monitor_name-* | cut -d'-' -f3 | xargs`
	local counter
	for counter in `get_counters_for_monitor $munin_dir $hostname $monitor_name`; do
		local data=`get_last_data_for_counter $munin_dir $hostname $monitor_name $counter`
		data_for_update="$data_for_update;$counter:$data"
	done
	# remove first ';' as it is unneeded
	data_for_update=${data_for_update:1}

	# call monitis api to update data
	monitis_update_custom_monitor_data $API_KEY $SECRET_KEY $monitor_tag "$data_for_update"
}

# returns last data in monitor using 'rrdtool lastupdate'
# $1 - munin directory
# $2 - hostname
# $3 - monitor name
get_last_data_for_counter() {
	local munin_dir=$1; shift
	local hostname=$1; shift
	local monitor_name=$1; shift
	local counter=$1; shift
	# TODO some end in c.rrd and d.rrd
	MUNIN_RRD_SUFFIX=".rrd"
	rrdtool lastupdate $munin_dir/$hostname/$hostname-$monitor_name-$counter-*$MUNIN_RRD_SUFFIX | tail -1 | cut -d' ' -f2
}

"$@"
