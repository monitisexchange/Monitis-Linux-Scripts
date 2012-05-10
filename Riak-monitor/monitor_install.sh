#!/bin/bash
#############################################################################
#	RIAK MONITOR INSTALL SCRIPT                                         #
#	Author: Arthur Tumanyan <arthurtumanyan@yahoo.com>                  #
#	Company: Netangels <http://www.netangels.net>                       # 
#############################################################################
DIR='/opt'
RIAK_HOME='monitis-riak-monitor'
NAME='monitis-riak-monitor'
if [[ ! -f /usr/sbin/riak-admin ]];then
	echo "Can not find riak-admin"
	exit 2
fi
#
if [[ ! -f /usr/bin/curl ]];then
	echo "Can not find curl";
	exit 2;
fi
#
#set -xv
#
function copy_data()
{
	echo -n "Copying files to $1"
	cp -R monitor/* $1/
	ret="$?"
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
	crontab -l | { cat; echo "*/1 * * * * cd $1/$RIAK_HOME/ && $1/$RIAK_HOME/$NAME > /dev/null"; } | crontab -
	service cron restart
}
#
function remove_from_crontab()
{
	crontab -l|grep -v "$NAME" | { cat; } | crontab -
	service cron restart
}
#
function destroy_environment()
{
	echo -n "Removing directory $1/$RIAK_HOME "
	if [[ ! -d $1/$RIAK_HOME ]];then
		echo "NOTHING TO REMOVE"
	else
		rm -rf "$1/$RIAK_HOME"
		ret="$?"
		if [[ $ret -ne 0 ]];then
			echo " Fail!"
			exit 1
		else
			echo " Done"
		fi
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
#
ABSOLUTE_PATH="$1/$RIAK_HOME"

	echo -n "Creating directory $ABSOLUTE_PATH for script files"
	mkdir -p "$ABSOLUTE_PATH"
	ret="$?"
	if [[ $ret -ne 0 ]];then
		echo " Fail!"
		exit 1
	else
		echo " Done"
	fi
	copy_data $ABSOLUTE_PATH
	remove_from_crontab
	add_to_crontab $1
	chmod +x $ABSOLUTE_PATH/$NAME
	cd $ABSOLUTE_PATH/ && bash $NAME create
	cd - > /dev/null
	echo "Monitis Riak monitor install path is:  $ABSOLUTE_PATH"
	
}
#
echo -n "Enter the installation absolute path or Return for default value:"
read user_path

if [[ "x$user_path" == "x" ]];then
        echo "Default path is: $DIR"
else
        if [[ ! -d $user_path ]];then
                echo "No such directory...exiting "
                echo
		exit 1
	else
		DIR=$user_path
        fi
fi

#
if [[ "$1" == "destroy" ]];then
	if [[ -d $DIR ]];then
		destroy_environment $DIR
	fi
elif [[ -d $DIR ]];then
	prepare_environment $DIR
else
	fs_error_msg
fi

exit 0

