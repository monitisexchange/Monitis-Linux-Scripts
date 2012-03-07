## The file synchronization monitoring

This project presents the Linux Bash-script application that monitors file synchronization (FSM). It is implemeted as Monitis custom monitor and use the Monitis Open API.  
This project is based on Bash 4.x+ and require the Linux kernel 2.6.x or higher.

#### Content  

   Monitis Open API wrapper  

          monitis_api.sh        monitis api wrapper functions  
          monitis_constant.sh   monitis api wrapper constants (and configuration)  
          monitis_global.sh     monitis api wrapper global variables  
          monitis_util.sh       monitis api wrapper utility functions  

   Custom FSM monitor  

		  dmon_start.sh         custom monitor main part and executor  
          monitor_constant.sh   custom monitor constants (and configuration)  
          dir_synch.sh          custom monitor on remote server executor

#### Dependencies  

The current version of FSM monitor provide HTTP access to the Monitis main server so you have to have installed the __CURL__ library on Linux  machine where monitor will be run.  
Besides, the monitor uses Linux calculator (named '__bc__') to provide floating points calculations. Thus, you have to have installed Linux calculator too.  Also you need to have 
ssh access to remote servers which folders are monitored.
 
#### Used approach

The presented monitor in fact devided on two parts  

   - watching part
   - processing part

The watching part fetches the monitoring folders files list with corresponding checksums and accumulates necessary information. 
The processing part periodically reads the accumulated information, executes necessary comparisions and calculations and send them to Monitis main server.  
 
You can monitor as many folder as you need.   
If more than one folder is monitored, the programm will compare the succeeding folders defined in DIR_A with the same defined in DIR_B. 
I.e., if in the monitor-constants you  have declared:   

     declare -r DIR_A="/home/folder1.//./home/folder2"
     declare -r DIR_B="/opt/folder1.//./opt/folder2"

then the content of the folder "/home/folder1" on Host A will be compared with the content of the "/opt/folder1" folder on Host B.   
Consecutively, the content of the folder "/home/folder2" on Host A will be compared with the content of the "/opt/folder2" folder on Host B.   
_Note that the final results will consist of the accumulated results of all compared files._  

#### Customizing and Usage 

To use existing scripts you need to do some changes that will correspond your account and data  

   - in monitis_constant.sh  
       - replace ApiKey and SecretKey by your keys values (can be obtained from your Monitis account)  

   - in monitor_constant.sh   
       - replace HOST_A and HOST_B by your FSM address, destination host 1 and 2 addresses.
	   
       - replace DIR_A and DIR_B by your monitoring folders. Here DIR_A represents the folder(s) on host A and DIR_B the same on host B. Note: if you want 
	     to compare more than one folders then the folders paths must be separated by './/.' delimiter. For ex. declare -r DIR_A="/opt/synctest.//./opt/temp"
		 
       - replace MONITOR_TAG and MONITOR_TYPE by your desired names   
         (MONITOR_NAME is formed authomatically, so you don't need to specify it)

That's all. Now you can click on dmon_start.sh to run your custom file synchronization monitor.  

