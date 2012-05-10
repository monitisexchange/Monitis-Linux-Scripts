## MONITORING RIAK WITH MONITIS ##

Original Author: Arthur Tumanyan

Company: Netangels

Web Site: [http://www.netangels.net](http://www.netangels.net)

#### OVERVIEW ####

Riak-monitor is a monitoring tool, specially designed for monitis.com cloud based monitoring platform.  
It provides wide range of metrics which allows you to be informed about your Riak  cluster/node health, memory usage, etc.
	
The monitor consists of 8 parts:

		monitor_install.sh   - monitor installer
		monitis-riak-monitor - main monitor script
		monitis_api.sh       - provides API for monitor script
		monitis_constant.sh  - variable declarations & constants
		monitis_data.sh      - provides data fetching from riak (stores data fetching function)
		monitis_global.sh    - Declaration of global variables for Monitis Api
		monitis_util.sh      - Provides utility functions for Monitis Api
		ticktick.sh          - provides JSON functionality

#### INSTALLATION ####

__How to Install:__
	
Download the Riak-monitor from github
  <pre markdown=1>
     cd _riak-monitor-install-dir_
     bash monitor_install.sh
  </pre>

Enjoy!
	
__How to uninstall:__

  <pre markdown=1>
     cd _riak-monitor-install-dir_
     bash monitor_install.sh destroy   
  </pre>


This will send data every time you run it.  Set it up with Cron or any other  
scheduling agent to begin periodically sending data back to Monitis.  
You can check into the Monitis dashboard to view your Riak Stats.


#### DEPENDENCIES ####

        Bourne Again Shell
        An installed instance of Riak
        Curl

#### METRICS ####

  <pre markdown=1>
         Description                              Parameter name
	 ===============================================================================================
	 Virtual Memory Peak                            VmPeak 
	 Virtual Memory Size                            VmSize
	 Data	Segment Size                            VmData
	 File System Swap                               cached_memory
	 Number of PUTs                                 node_puts
	 Vnode index reads                              vnode_index_reads
	 Vnode index writes                             vnode_index_writes
	 Vnode index writes total                       vnode_index_writes_total
	 Vnode index writes postings                    vnode_index_writes_postings
	 Vnode index deletes                            vnode_index_deletes
	 Vnode index deletes postings                   vnode_index_deletes_postings
	 Vnode gets total                               vnode_gets_total
 	 Vnode puts total                               vnode_puts_total
	 Precommit fail                                 precommit_fail
	 PBC connects total                             pbc_connects_total
	 PBC connects                                   pbc_connects
	 PBCactive                                      pbc_active
  </pre>

#### OTHER ####

Be sure you have right to run monitor_install.sh script  
Change APIKEY & SECRETKEY in monitis_constant.sh according to your settings

