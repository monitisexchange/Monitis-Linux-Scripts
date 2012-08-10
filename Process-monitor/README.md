## The Process Custom Monitor ##

The current project represents the Bash script implementation of Monitis custom monitor approach that evaluate the health state of any process in Unix-like systems.  
It measures few important parameters of process and sends evaluation of health status into Monitis via the Monitis open API.  
The main purpose of current project is to show the possible way of using Monitis Open API for monitoring any process behavior.  
Naturally, a different variations of the presented code can be made in accordance user needs.  

#### Dependencies

  - This project is based on Bash 4.x+  
  - require the Linux kernel 2.6.x or higher  
  - require to have installed the __curl__ library that provides all HTTP connections  
  - uses Linux calculator (named '__bc__') to provide floating points calculations  

#### Content  

    Monitis Open API wrapper

          monitis_api.sh        monitis api wrapper functions  
          monitis_constant.sh   monitis api wrapper constants (and configuration)  
          monitis_global.sh     monitis api wrapper global variables  
          monitis_util.sh       monitis api wrapper utility functions  

    Custom Process monitor  

          proc_monitor.sh      custom monitor main part  
          monitor_constant.sh   custom monitor constants (and configuration)  
          monitor_start.sh      custom monitor main executor 
 
    Additional part  

          monitor_getdata.sh    module for getting data from Monitis
          ticktick.sh           JSON engine for bash
          start.sh              Starts process-monitor as a daemon
          stop.sh               Stops daemon process-monitor

#### Measuring parameters

The current Process monitor measures the following parameters  

   - cpu - The percentage of cpu utilization of the process which is a ratio of CPU time used to the process total running time (cputime/realtime).
   - mem - The percentage of memory utilization of the process which is a ratio of the Resident Set Size to the physical memory.
   - virt - Virtual memory size in Mbytes.
   - res - Resident Set Size (text, data, stack) that is a real occupied memory size in Mbytes.
   - ofd - The total number of file descriptors that currently allocated and open for process.
   - osd - The number of open socket descriptors that are a part of 'ofd'
   - ofd_pr - The percentage of the total number of file descriptors with respect to the maximum allowed count of descriptors for process.
   - threads - The number of threads in this process (since Linux 2.6).
   - uptime - The elapsed time since the process was started.
   - status - the evaluation of process healt
      - DOWN - there is no such process (could be down)
      - NOK - Process is running but some dangerous situation are detected
         - CPU or Memory utilization is too big (more than 95%)
         - Open File Descriptors count near to allowed maximum (ofd_pr > 95%)
      - OK - No any errors are detected
 
Please NOTE that current monitor prints out few parameters as an additional result.  

  - VmPeak - The detected peak of virtual memory size in Kbytes
  - VmHWM - The detected peak of Resident Set Size in Kbytes ("high water mark").
  - VmData - The size of data segments in Kbytes.
  - VmStk - The size of stack segments in Kbytes.

#### Customizing and Usage 

To use existing scripts you need to do some changes that will correspond your account and data  

  - in monitis_constant.sh  
     - replace _ApiKey_ and _SecretKey_ by your keys values (can be obtained from your [Monitis](http://www.monitis.com) account)
  - in monitor_constant.sh   
     - replace *PROC_CMD* and/or *PROC_ID* by your monitored process parameters (command name, process ID)  
       _Notice that you may provide one of COMMAND or PID or both together. The monitor will try to define an omitted parameter._
     - replace MONITOR_NAME, MONITOR_TAG and MONITOR_TYPE by your desired names (optional)  

That's all.  

Now you can run your custom process-monitor by using e.g. the following command.  

        start.sh -d <duration in min> -p <pid of process> -c <command of process> -s <host of process>

It will run monitor as a daemon process and prints only error messages.  
Note
 
  - all parameters are optional. 
  - the duration has the minimum value limit (5 min) that is defined in the "monitor_constant.sh"
  - the "command of process" should be unique otherwise the first found command with given parameter will be monitored
  - usage of command line parameters allow to run few process-monitors to monitor various processes.
  - the name of monitor is composed as the following:  "Process\_\<host of process | 127.0.0.1\>\_\<command of process | memcached\>"
 
The stop of process-monitor can be done by the following command

        stop.sh <command of process>

The command line parameter is _optional_. The command will stop all process-monitors if the "command for process" isn't given.

#### Testing 

To check the correctness of monitor workability, some tests was done for Node.js server that was under real load.

<a href="http://i.imgur.com/7SpvX"><img src="http://i.imgur.com/7SpvX.png" title="Process monitor test" /></a>

The double-clicking on any line switches desktop to show additional result

<a href="http://i.imgur.com/WKsb9"><img src="http://i.imgur.com/WKsb9.png" title="Process monitor test" /></a>

Naturally, the graphical view can be shown on desktop also

<a href="http://i.imgur.com/6R5hi"><img src="http://i.imgur.com/6R5hi.png" title="process monitor test" /></a>



