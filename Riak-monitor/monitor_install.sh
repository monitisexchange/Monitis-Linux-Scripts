#!/bin/bash
#############################################################################
#	RIAK MONITOR INSTALL SCRIPT                                         #
#	Author: Arthur Tumanyan <arthurtumanyan@yahoo.com>                  #
#	Company: Netangels <http://www.netangels.net>                       # 
#############################################################################
DIR='/opt'
DIR2='/usr'
RIAK_HOME='monitis-riak-monitor'
#
function copy_data()
{
	echo -n "Copying files to $1"
	ret=$(cp -R monitor/* $1/)
	if [[ $ret -ne 0 ]];then
		echo " Fail!"
		exit 1
	else
		echo " Done"
	fi
}
#
function add_to_crontab()
{
	crontab -l | { cat; echo "*/1 * * * * $1/$RIAK_HOME/riakm_start.sh > 2>&1"; } | crontab -
	service cron restart
}
#
function remove_from_crontab()
{
	crontab -l|grep -v 'riakm_start.sh' | { cat; } | crontab -
	service cron restart
}
#
function destroy_environment()
{
	echo -n "Removing directory $1/$RIAK_HOME "
	ret=$(rm -rf "$1/$RIAK_HOME")
	if [[ $ret -ne 0 ]];then
		echo " Fail!"
		exit 1
	else
		echo " Done"
	fi
	remove_from_crontab
}
#
function fs_error_msg()
{
	echo "Is your filesystem broken?"
	exit 1
}
#
function prepare_environment()
{
	echo -n "Creating directory $1/$RIAK_HOME for script files"
	ret=$(mkdir -p "$1/$RIAK_HOME")
	if [[ $ret -ne 0 ]];then
		echo " Fail!"
		exit 1
	else
		echo " Done"
	fi
	copy_data $1/$RIAK_HOME
	add_to_crontab $1
	(cd $1/$RIAK_HOME/ && bash riakm_start.sh create)
	echo "Monitis Riak monitor install path is:  $1/$RIAK_HOME"
	cat Readme.md
	
}
#
#
if [[ "$1" == "destroy" ]];then
	if [[ -d $DIR ]];then
		destroy_environment $DIR
		exit 0
	elif [[ -d $DIR2 ]];then
		destroy_environment $DIR2
		exit 0
	else
		fs_error_msg
	fi
fi

if [[ -d $DIR ]];then
	prepare_environment $DIR
elif [[ -d $DIR2 ]];then
	prepare_environment $DIR2
else
	fs_error_msg
fi
