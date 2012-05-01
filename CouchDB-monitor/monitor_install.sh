#!/bin/bash
#############################################################################
#	COUCH-DB MONITOR INSTALL SCRIPT                                         #
#	Author: Arthur Tumanyan <arthurtumanyan@yahoo.com>                  #
#	Company: Netangels <http://www.netangels.net>                       # 
#############################################################################
DIR='/opt'
DIR2='/usr'
COUCH_HOME='monitis-couchdb-monitor'
NAME='monitis-couchdb-monitor'
JSAWK=jsawk
#
if [[ ! -f /usr/bin/js ]];then
	echo "Can not find js"
	echo "Do apt-get spidermonkey-bin to install it"
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
	crontab -l | { cat; echo "*/1 * * * * cd $1/$COUCH_HOME/ && $1/$COUCH_HOME/$NAME > /dev/null"; } | crontab -
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
	echo -n "Removing directory $1/$COUCH_HOME "
	if [[ ! -d $1/$COUCH_HOME ]];then
		echo "NOTHING TO REMOVE"
	else
	[[ -f /usr/bin/$JSAWK ]] && rm /usr/bin/$JSAWK
	ret=$(rm -rf "$1/$COUCH_HOME")
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
ABSOLUTE_PATH="$1/$COUCH_HOME"
#
	echo -n "Creating directory $ABSOLUTE_PATH for script files"
	ret=$(mkdir -p "$ABSOLUTE_PATH")
	if [[ $ret -ne 0 ]];then
		echo " Fail!"
		exit 1
	else
		echo " Done"
	fi
	[[ ! -f /usr/bin/$JSAWK ]] && cp $JSAWK $ABSOLUTE_PATH/$JSAWK && ln -s $ABSOLUTE_PATH/$JSAWK /usr/bin/$JSAWK && chmod +x /usr/bin/$JSAWK
	copy_data $ABSOLUTE_PATH
	remove_from_crontab
	add_to_crontab $1
	chmod +x $ABSOLUTE_PATH/$NAME
	cd $ABSOLUTE_PATH/ && bash $NAME create
	cd - > /dev/null
	echo "Monitis CouchDB monitor install path is:  $ABSOLUTE_PATH"
	
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
