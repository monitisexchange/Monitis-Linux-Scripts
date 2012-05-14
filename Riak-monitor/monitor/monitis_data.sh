#!/bin/bash
#############################################################################
#	RIAK MONITOR START SCRIPT                                           #
#	Author: Arthur Tumanyan <arthurtumanyan@yahoo.com>                  #
#	Company: Netangels <http://www.netangels.net>                       # 
#############################################################################
#
# sources included
SOURCE_PATH=
#

source ${SOURCE_PATH}monitis_constant.sh || exit 2
#
function get_data(){
	#
	data=$($RIAK_ADMIN status|grep -v '<<'|awk '{print $1,$3}'|grep -v '{'|tail -n +5 > $TMP_RIAK)
	#
	RIAK_PID=$(ps aux|grep "\-progname riak"|grep -v 'grep'|awk '{print $2}')
	#
	value=$(cat /proc/$RIAK_PID/status|grep 'VmPeak'|awk '{print $2}')
	if [[ "x$value" == "x" ]] ; then
		value=-1
	fi
	UOM=$(cat /proc/$RIAK_PID/status|grep 'VmSize'|awk '{print $3}')
	postdata=$postdata"vm_peak:$value;"
	result=$result"vm_peak:Virtual+Memory+Peak:$UOM:2;";
	#
	value=$(cat /proc/$RIAK_PID/status|grep 'VmSize'|awk '{print $2}')
	if [[ "x$value" == "x" ]] ; then
		value=-1
	fi
	UOM=$(cat /proc/$RIAK_PID/status|grep 'VmSize'|awk '{print $3}')
	postdata=$postdata"vm_size:$value;"
	result=$result"vm_size:Virtual+Memory+Size:$UOM:2;";
	#
	value=$(cat /proc/$RIAK_PID/status|grep 'VmData'|awk '{print $2}')
	if [[ "x$value" == "x" ]] ; then
		value=-1
	fi
	UOM=$(cat /proc/$RIAK_PID/status|grep 'VmData'|awk '{print $3}')
	postdata=$postdata"vm_data:$value;"
	result=$result"vm_data:Data+Segment+Size:$UOM:2;";
	#
	#
	value=$(cat /proc/meminfo|grep 'Cached'|head -1|awk '{print $2}')
	if [[ "x$value" == "x" ]] ; then
		value=-1
	fi
	UOM=$(cat /proc/meminfo|grep 'Cached'|head -1|awk '{print $3}')
	postdata=$postdata"cached_memory:$value;"
	result=$result"cached_memory:File+System+Swap:$UOM:2;";
	#
	UOM=
	#
	value=$(grep 'node_puts' $TMP_RIAK|head -1|awk '{print $2}')
	if [[ "x$value" == "x" ]] ; then
		value=-1
	fi
	postdata=$postdata"node_puts:$value;"
	result=$result"node_puts:Number+of+PUTs:$UOM:2;";
	#
	#
	value=$(grep 'vnode_index_reads' $TMP_RIAK|head -1|awk '{print $2}')
	if [[ "x$value" == "x" ]] ; then
		value=-1
	fi
	postdata=$postdata"vnode_index_reads:$value;"
	result=$result"vnode_index_reads:Vnode+index+reads:$UOM:2;";
	#
	value=$(grep 'vnode_index_writes' $TMP_RIAK|head -1|awk '{print $2}')
	if [[ "x$value" == "x" ]] ; then
		value=-1
	fi
	postdata=$postdata"vnode_index_writes:$value;"
	result=$result"vnode_index_writes:Vnode+index+writes:$UOM:2;";
	#
	value=$(grep 'vnode_index_writes_total' $TMP_RIAK|head -1|awk '{print $2}')
	if [[ "x$value" == "x" ]] ; then
		value=-1
	fi
	postdata=$postdata"vnode_index_writes_total:$value;"
	result=$result"vnode_index_writes_total:Vnode+index+writes+total:$UOM:2;";
	#
	value=$(grep 'vnode_index_writes_postings' $TMP_RIAK|head -1|awk '{print $2}')
	if [[ "x$value" == "x" ]] ; then
		value=-1
	fi
	postdata=$postdata"vnode_index_writes_postings:$value;"
	result=$result"vnode_index_writes_postings:Vnode+index+writes+postings:$UOM:2;";
	#
	value=$(grep 'vnode_index_deletes' $TMP_RIAK|head -1|awk '{print $2}')
	if [[ "x$value" == "x" ]] ; then
		value=-1
	fi
	postdata=$postdata"vnode_index_deletes:$value;"
	result=$result"vnode_index_deletes:Vnode+index+deletes:$UOM:2;";
	#
	value=$(grep 'vnode_index_deletes_postings' $TMP_RIAK|head -1|awk '{print $2}')
	if [[ "x$value" == "x" ]] ; then
		value=-1
	fi
	postdata=$postdata"vnode_index_deletes_postings:$value;"
	result=$result"vnode_index_deletes_postings:Vnode+index+deletes+postings:$UOM:2;";
	#
	value=$(grep 'read_repairs' $TMP_RIAK|head -1|awk '{print $2}')
	if [[ "x$value" == "x" ]] ; then
		value=-1
	fi
	postdata=$postdata"read_repairs:$value;"
	result=$result"read_repairs:Read+repairs:$UOM:2;";
	#
	value=$(grep 'vnode_gets_total' $TMP_RIAK|head -1|awk '{print $2}')
	if [[ "x$value" == "x" ]] ; then
		value=-1
	fi
	postdata=$postdata"vnode_gets_total:$value;"
	result=$result"vnode_gets_total:Vnode+gets+total:$UOM:2;";
	#
	value=$(grep 'vnode_puts_total' $TMP_RIAK|head -1|awk '{print $2}')
	if [[ "x$value" == "x" ]] ; then
		value=-1
	fi
	postdata=$postdata"vnode_puts_total:$value;"
	result=$result"vnode_puts_total:Vnode+puts+total:$UOM:2;";
	#
	value=$(grep 'precommit_fail' $TMP_RIAK|head -1|awk '{print $2}')
	if [[ "x$value" == "x" ]] ; then
		value=-1
	fi
	postdata=$postdata"precommit_fail:$value;"
	result=$result"precommit_fail:Precommit+fail:$UOM:2;";
	#
	value=$(grep 'postcommit_fail' $TMP_RIAK|head -1|awk '{print $2}')
	if [[ "x$value" == "x" ]] ; then
		value=-1
	fi
	postdata=$postdata"postcommit_fail:$value;"
	result=$result"postcommit_fail:Postcommit+fail:$UOM:2;";
	#
	value=$(grep 'pbc_connects_total' $TMP_RIAK|head -1|awk '{print $2}')
	if [[ "x$value" == "x" ]] ; then
		value=-1
	fi
	postdata=$postdata"pbc_connects_total:$value;"
	result=$result"pbc_connects_total:PBC+connects+total:$UOM:2;";
	#
	value=$(grep 'pbc_connects' $TMP_RIAK|head -1|awk '{print $2}')
	if [[ "x$value" == "x" ]] ; then
		value=-1
	fi
	postdata=$postdata"pbc_connects:$value;"
	result=$result"pbc_connects:PBC+connects:$UOM:2;";
	#
	value=$(grep 'pbc_active' $TMP_RIAK|head -1|awk '{print $2}')
	if [[ "x$value" == "x" ]] ; then
		value=-1
	fi
	postdata=$postdata"pbc_active:$value;"
	result=$result"pbc_active:PBC+active:$UOM:2;";
	#
	#end of get_data
	test -f $TMP_RIAK && rm $TMP_RIAK > /dev/null
	#
}
#

