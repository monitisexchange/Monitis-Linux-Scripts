#!/bin/bash
#############################################################################
#       COUCH MONITOR START SCRIPT                                          #
#       Author: Arthur Tumanyan <arthurtumanyan@yahoo.com>                  #
#       Company: Netangels <http://www.netangels.net>                       #
#############################################################################
#
#set -x
# sources included
SOURCE_PATH=
source ${SOURCE_PATH}monitis_constant.sh || exit 2
#
function get_data()
{
#
data=$($CURL -s $STATLINK > $TMP_COUCH)
#
COUCH_PID=$(netstat -lpt|grep '5984'|awk '{print $7}'|awk -F '/' '{print $1}')
#
vm_peak=$(cat /proc/$COUCH_PID/status|grep 'VmPeak'|awk '{print $2}')
UOM=$(cat /proc/$COUCH_PID/status|grep 'VmSize'|awk '{print $3}')
postdata=$postdata"vm_peak:$vm_peak;"
result=$result"vm_peak:Virtual+Memory+Peak:$UOM:2;";
#
vm_size=$(cat /proc/$COUCH_PID/status|grep 'VmSize'|awk '{print $2}')
UOM=$(cat /proc/$COUCH_PID/status|grep 'VmSize'|awk '{print $3}')
postdata=$postdata"vm_size:$vm_size;"
result=$result"vm_size:Virtual+Memory+Size:$UOM:2;";
#
vm_data=$(cat /proc/$COUCH_PID/status|grep 'VmData'|awk '{print $2}')
UOM=$(cat /proc/$COUCH_PID/status|grep 'VmData'|awk '{print $3}')
postdata=$postdata"vm_data:$vm_data;"
result=$result"vm_data:Data+Segment+Size:$UOM:2;";
#
#
cached_memory=$(cat /proc/meminfo|grep 'Cached'|head -1|awk '{print $2}')
UOM=$(cat /proc/meminfo|grep 'Cached'|head -1|awk '{print $3}')
postdata=$postdata"cached_memory:$cached_memory;"
result=$result"cached_memory:File+System+Swap:$UOM:2;";
#
UOM='NA'
#
#couchdb
for ITER in "open_databases" "database_reads" "database_writes" "request_time" "open_os_files"
do
        val=$($JSAWK "return this.couchdb[\"$ITER\"].current" < $TMP_COUCH)
        if [[ -z $val ]];then
                val=0
        fi
        desc=$(cat $TMP_COUCH|$JSAWK "return this.couchdb[\"$ITER\"].description"|sed "s/number of//g" |sed "s/length of//g" | tr [:space:] '+')
        postdata=$postdata"$ITER:$val;"
        result=$result"$ITER:$desc:$UOM:2;";

done
#
#httpd
for ITER in "requests" "bulk_requests" "view_reads" "clients_requesting_changes" "temporary_view_reads"
do
        val=$($JSAWK "return this.httpd[\"$ITER\"].current" < $TMP_COUCH)
        if [[ -z $val ]];then
                val=0
        fi
        desc=$(cat $TMP_COUCH|$JSAWK "return this.httpd[\"$ITER\"].description"|sed "s/number of//g" |sed "s/length of//g" | tr [:space:] '+')
        postdata=$postdata"$ITER:$val;"
        result=$result"$ITER:$desc:$UOM:2;";
done
#
additionalPData="[{"
#httpd_request_methods
for ITER in "DELETE" "HEAD" "POST" "PUT" "MOVE" "GET" "COPY"
do
        val=$($JSAWK "return this.httpd_request_methods[\"$ITER\"].current" < $TMP_COUCH)
        if [[ -z $val ]];then
                val=0
        fi
 desc=$(cat $TMP_COUCH|$JSAWK "return this.httpd_request_methods[\"$ITER\"].description"|sed "s/number of//g" |sed "s/length of//g"|sed "s/HTTP//g"|sed "s/requests//g"|tr [:space:] '+')
        additionalPData=$additionalPData\"$ITER\":$val\,;
        additionalResult=$additionalResult$ITER:$desc:$UOM:2:$UOM\;;
done
#
#httpd_status_codes
for ITER in "400" "201" "403" "409" "200" "202" "404" "301" "405" "500" "401" "304" "412"
do
        val=$($JSAWK "return this.httpd_status_codes[\"$ITER\"].current" < $TMP_COUCH)
        if [[ -z $val ]];then
                val=0
        fi
        desc=$(cat $TMP_COUCH|$JSAWK "return this.httpd_status_codes[\"$ITER\"].description"|sed "s/number of//g" |sed "s/length of//g"|sed "s/HTTP//g"|sed "s/responses//g" | tr [:space:] '+')
        additionalPData=$additionalPData\"$ITER\":$val\,;
        additionalResult=$additionalResult$ITER:$desc:$UOM:2:$UOM\;;
done
additionalPData=$additionalPData"}]";
#
echo
echo
#end of get_data
#test -f $TMP_COUCH && rm $TMP_COUCH > /dev/null
#
}
#
