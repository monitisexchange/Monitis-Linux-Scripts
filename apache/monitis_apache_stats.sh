#!/bin/bash
# apache stats monitor for Monitis
# Written by Michael Chletsos 2011-06-18

MONITOR="apacheMonitor"
WGET=`which wget`
URL="http://localhost/server-status?auto"
RET=`$WGET --quiet -O - "$URL"`
MONITIS_ADD_DATA="~/monitis/Monitis-Linux-Scripts/API/monitis_add_data.sh"

RESULT=
IFS="$(echo -e "\n\r")"
for i in ${RET}
do 
   TAG=`echo $i | awk -F": " '{print $1}'`
   VAL=`echo $i | awk -F": " '{print $2}'`
   if [[ $TAG != "Scoreboard" ]]
   then
     RESULT=$RESULT`echo $TAG | cut -d" " -f2``echo ":$VAL;"`
   fi
done

if [[ $RESULT != "" ]]
then
   $MONITIS_ADD_DATA -m $MONITOR -r $RESULT -a API_Key -s Secret_Key > /dev/null
fi


exit 0
