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
	    status="NOK"
	fi
	
	if [ $errors -gt 0 ]
	then
	    problem="Problems detected"
	    CNT=0
	    while [[ ("$CNT" != "$errors") ]]
	    do
	        problem="$problem + ${MSG[$CNT]}"
	        CNT=$(($CNT+1))
	    done
	    details="$details+${problem}"
	fi
	local param="status:$status;test:$test"

	return_value="$param | $details"
	return 0
}
