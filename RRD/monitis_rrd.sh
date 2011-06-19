#!/bin/bash

# monitis_rrd.sh - monitis common interface for integration with
# RRD system such as munin, cacti, etc.
# Written by Dan Fruehauf malkodan@gmail.com

source monitis_api.sh || exit 1

# these are the functions you have to implement in an interface
declare -r INTERFACE_FUNCTIONS="list_monitors list_counters_for_monitor add_monitor update_data_for_monitor"

declare -r RRD_TAG_PREFIX="RRD"

# canonize the monitor name, so it's standard
# essentially we'll just add a 'RRD_${hostname}_${plugin_name}_' prefix
# $1 - monitor name
_canonize_monitor_tag_from_name() {
	local hostname=$1; shift
	local plugin_name=$1; shift
	local monitor_name=$1; shift
	echo "${RRD_TAG_PREFIX}_${hostname}_${plugin_name}_${monitor_name}"
}

# validates we're going to invoke a proper function
# $1 - function name
_validate_function() {
	local function_name=$1; shift
	if [ x"$function_name" == x ] || ! echo $INTERFACE_FUNCTIONS | grep -q "\b$function_name\b"; then
		echo "Valid function are '$INTERFACE_FUNCTIONS'"
		exit 1
	fi
}

# main
# $1 - plugin name (munin, cacti, etc)
# $2 - function name (munin, cacti, etc)
# $@ - additional plugin parameters
main() {
	local plugin_name=$1; shift
	local function_name=$1; shift
	_validate_function $function_name
	source $plugin_name/interface.sh || exit 1
	$function_name "$@"
}

main "$@"
