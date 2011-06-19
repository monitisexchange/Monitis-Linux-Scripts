#!/bin/bash
#!/bin/sh 
# nagios wrapper for Monitis
# Written by Michael Chletsos 2011-06-18

RESULT=
NAGIOSCMD=`/usr/lib/nagios/plugins/check_load $*`
RC=$?

#grab state first
STATUS=`echo $NAGIOSCMD | awk '{print $1}'`
if [[ $STATUS == 'OK' ]]
then
  RESULT="state:$STATUS;state_val:1;"
elif [[ $STATUS == 'WARNING' ]] 
then
  RESULT="state:$STATUS;state_val:.5;"
elif [[ $STATUS == 'CRITICAL' ]]
then
  RESULT="state:$STATUS;state_val:0;"
fi

OUT=`echo $NAGIOSCMD | awk -F\| '{print $2}'`

for i in $OUT
do
  RESULT=$RESULT`echo $i | awk -F\; '{sub(/=/,":"); print $1";"}'`
done

if [[ $RESULT != "" ]]
then
  ../API/monitis_add_data.sh -m loadMonitor -r $RESULT -a 3P9SPCP910D1FLKBLB0IV3UUNG -s 3L1HMU1H923CBEDQS7O4N9HO7K > /dev/null
fi

echo "$NAGIOSCMD"

# exit with return value of nagios command
exit $RC
