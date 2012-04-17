#!/bin/bash
# nginx stats monitor for Monitis
# Written by Michael Chletsos 2012-04-04

MONITOR="nginxQueueMonitor"
WGET=`which wget`
URL="http://localhost/nginx-status"
RET=`$WGET --quiet -O - "$URL"`
MONITIS_ADD_DATA="~/monitis/Monitis-Linux-Scripts/API/monitis_add_data.sh"

RESULT=
IFS="$(echo -e "\n\r")"
count=0
for i in ${RET}
do 
   TAG=`echo $i | awk -F": " '{print $1}'`
   VAL=`echo $i | awk -F": " '{print $2}'`
   if [[ $TAG == "Active connections" ]]
   then
     RESULT=$RESULT`echo "Total:$VAL;"`
   elif [[ $count == 3 ]]
   then
     RESULT=$RESULT`echo "Reading:"``echo $i | awk -F": " '{print $2}' | cut -d" " -f1``echo ";Writing:"``echo $i | awk -F": " '{print $3}' | cut -d" " -f1``echo ";Waiting:"``echo $i | awk -F": " '{print $4}' | cut -d" " -f1`
   fi
count=$(($count+1))
done
if [[ $RESULT != "" ]]
then
   $MONITIS_ADD_DATA -m $MONITOR -r $RESULT -a API_Key -s Secret_Key > /dev/null
fi


exit 0
