MONITORING RIAK WITH MONITIS

Original Author: Arthur Tumanyan
Company: Netangels
Web Site: http://www.netangels.net

OVERVIEW:
---------
These scripts allow a user to easily get some monitoring around their Riak installs using Monitis.


INSTALLATION:
-------------
How to Install:
	Download the Riak-monitor from github

	cd <riak-monitor-install-dir>
	bash monitor_install.sh
	Enjoy!
How to uninstall:

	cd <riak-monitor-install-dir>
	bash monitor_install.sh destroy   


This will send data every time you run it.  Set it up with Cron or any other
scheduling agent to begin periodically sending data back to Monitis.  You can 
check into the Monitis dashboard to view your Riak Stats.


DEPENDENCIES:
-------------
Bourne Again Shell
An installed instance of Riak
Curl

OTHER:
------
Be sure you have right to run monitor_install.sh script
Change APIKEY & SECRETKEY in monitis_constant.sh according to your settings
