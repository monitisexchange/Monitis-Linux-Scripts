#!/bin/bash
:
#
#set -x
declare data
declare postdata
declare result
declare UOM
UOM=''
#
if [[ "$UID" != 0 ]];then
	echo "Must be root"
	exit 1
fi
function get_data()
{
#
data=`riak-admin status|grep -v '<<'|awk '{print $1,$3}'|grep -v '{'|tail -n +5 > .tmp_riak`
#
RIAK_PID=$(ps aux|grep "\-progname riak"|grep -v 'grep'|awk '{print $2}')
#
vm_peak=$(cat /proc/$RIAK_PID/status|grep 'VmPeak'|awk '{print $2}')
UOM=$(cat /proc/$RIAK_PID/status|grep 'VmSize'|awk '{print $3}')
postdata=$postdata"vm_peak:$vm_peak;"
result=$result"vm_peak:Virtual+Memory+Peak:$UOM:2;";
#
vm_size=$(cat /proc/$RIAK_PID/status|grep 'VmSize'|awk '{print $2}')
UOM=$(cat /proc/$RIAK_PID/status|grep 'VmSize'|awk '{print $3}')
postdata=$postdata"vm_size:$vm_size;"
result=$result"vm_size:Virtual+Memory+Size:$UOM:2;";
#
vm_data=$(cat /proc/$RIAK_PID/status|grep 'VmData'|awk '{print $2}')
UOM=$(cat /proc/$RIAK_PID/status|grep 'VmData'|awk '{print $3}')
postdata=$postdata"vm_data:$vm_data;"
result=$result"vm_data:Data+Segment+Size:$UOM:2;";
#
#
cached_memory=$(cat /proc/meminfo|grep 'Cached'|head -1|awk '{print $2}')
UOM=$(cat /proc/meminfo|grep 'Cached'|head -1|awk '{print $3}')
postdata=$postdata"cached_memory:$cached_memory;"
result=$result"cached_memory:File+System+Swap:$UOM:2;";
#
UOM=
#
node_puts=$(grep 'node_puts' .tmp_riak|head -1|awk '{print $2}')
postdata=$postdata"node_puts:$node_puts;"
result=$result"node_puts:Number+of+PUTs:$UOM:2;";
#
#
vnode_index_reads=$(grep 'vnode_index_reads' .tmp_riak|head -1|awk '{print $2}')
postdata=$postdata"vnode_index_reads:$vnode_index_reads;"
result=$result"vnode_index_reads:Vnode+index+reads:$UOM:2;";
#
vnode_index_writes=$(grep 'vnode_index_writes' .tmp_riak|head -1|awk '{print $2}')
postdata=$postdata"vnode_index_writes:$vnode_index_writes;"
result=$result"vnode_index_writes:Vnode+index+writes:$UOM:2;";
#
vnode_index_writes_total=$(grep 'vnode_index_writes_total' .tmp_riak|head -1|awk '{print $2}')
postdata=$postdata"vnode_index_writes_total:$vnode_index_writes_total;"
result=$result"vnode_index_writes_total:Vnode+index+writes+total:$UOM:2;";
#
vnode_index_writes_postings=$(grep 'vnode_index_writes_postings' .tmp_riak|head -1|awk '{print $2}')
postdata=$postdata"vnode_index_writes_postings:$vnode_index_writes_postings;"
result=$result"vnode_index_writes_postings:Vnode+index+writes+postings:$UOM:2;";
#
vnode_index_deletes=$(grep 'vnode_index_deletes' .tmp_riak|head -1|awk '{print $2}')
postdata=$postdata"vnode_index_deletes:$vnode_index_deletes;"
result=$result"vnode_index_deletes:Vnode+index+deletes:$UOM:2;";
#
vnode_index_deletes_postings=$(grep 'vnode_index_deletes_postings' .tmp_riak|head -1|awk '{print $2}')
postdata=$postdata"vnode_index_deletes_postings:$vnode_index_deletes_postings;"
result=$result"vnode_index_deletes_postings:Vnode+index+deletes+postings:$UOM:2;";
#
read_repairs=$(grep 'read_repairs' .tmp_riak|head -1|awk '{print $2}')
postdata=$postdata"read_repairs:$read_repairs;"
result=$result"read_repairs:Read+repairs:$UOM:2;";
#
vnode_gets_total=$(grep 'vnode_gets_total' .tmp_riak|head -1|awk '{print $2}')
postdata=$postdata"vnode_gets_total:$vnode_gets_total;"
result=$result"vnode_gets_total:Vnode+gets+total:$UOM:2;";
#
vnode_puts_total=$(grep 'vnode_puts_total' .tmp_riak|head -1|awk '{print $2}')
postdata=$postdata"vnode_puts_total:$vnode_puts_total;"
result=$result"vnode_puts_total:Vnode+puts+total:$UOM:2;";
#
precommit_fail=$(grep 'precommit_fail' .tmp_riak|head -1|awk '{print $2}')
postdata=$postdata"precommit_fail:$precommit_fail;"
result=$result"precommit_fail:Precommit+fail:$UOM:2;";
#
postcommit_fail=$(grep 'postcommit_fail' .tmp_riak|head -1|awk '{print $2}')
postdata=$postdata"postcommit_fail:$postcommit_fail;"
result=$result"postcommit_fail:Postcommit+fail:$UOM:2;";
#
pbc_connects_total=$(grep 'pbc_connects_total' .tmp_riak|head -1|awk '{print $2}')
postdata=$postdata"pbc_connects_total:$pbc_connects_total;"
result=$result"pbc_connects_total:PBC+connects+total:$UOM:2;";
#
pbc_connects=$(grep 'pbc_connects' .tmp_riak|head -1|awk '{print $2}')
postdata=$postdata"pbc_connects:$pbc_connects;"
result=$result"pbc_connects:PBC+connects:$UOM:2;";
#
pbc_active=$(grep 'pbc_active' .tmp_riak|head -1|awk '{print $2}')
postdata=$postdata"pbc_active:$pbc_active;"
result=$result"pbc_active:PBC+active:$UOM:2;";
#
#end of get_data
}
#
#
rm .tmp_riak
