#!/bin/bash
#
# the sample of monitor measurement module
#

# sorces included
source monitor_constant.sh    || exit 2

function get_measure() {
	local details="details"

    local rand=$RANDOM
	local test=$rand
	(( test %= $RANGE ))
	#echo "*********** Analizing ****************"
	local status="OK"
	
	errors=0
	if [[ $test -gt $THRESHOLD ]]
	then
	    MSG[$errors]="WARNING - too big test number"
	    errors=$(($errors+1))
	fi
	
	if [[ ($errors -gt 0) ]] ; then
	    details={"$(uri_escape \"details\":\"Problems detected\")"}
	    CNT=0
	    while [[ ("$CNT" != "$errors") ]] ; do
	        details=$details,{"$(uri_escape \"details\":\"${MSG[$CNT]}\")"}
	        CNT=$(($CNT+1))
	    done
	    status="NOK"
	else
		details={"$(uri_escape \"details\":\"OK\")"}
		status="OK"		
	fi
	local param="status:$status;test:$test;additionalResults:[$details]"

	return_value="$param"
	return 0
}
