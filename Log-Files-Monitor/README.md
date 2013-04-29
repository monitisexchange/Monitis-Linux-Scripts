## The selective monitor of textual log-file

This project presents the Linux Bash-script wrapper for the Monitis Open API.  
As sample, the selective monitor of textual log-files is developed.  
This project is based on Bash 4.x+ and require the Linux kernel 2.6.x or higher.

Content  

    Monitis Open API wrapper

          monitis_api.sh            monitis api wrapper functions  
          monitis_constant.sh       monitis api wrapper constants (and configuration)  
          monitis_global.sh         monitis api wrapper global variables  
          monitis_util.sh           monitis api wrapper utility functions  

    Custom textual log file monitor  

          monitor.sh                custom monitor main part  
          monitor_constant.sh       custom monitor constants (and configuration)  
          monitor_test.sh           custom monitor main executor  
          log_simulation.sh         log simulator (for testing purpose only)  

    Processing part  

        start_test.sh               runs conveyor that contains log-simulator, monitor and executor (uses xterminal)
        start.sh                    runs both monitor and executor parts (deamon processes - for production use)
        stop.sh                     stops conveyor all parts

#### Customizing and Usage 

To use existing scripts you need to do some changes that will correspond your account and data

     - in monitis_constant.sh replace ApiKey and SecretKey by your keys values (can be obtained from your Monitis account)  
     - in monitor_constant.sh   

		o - replace MONITOR_NAME, MONITOR_TAG and MONITOR_TYPE by your desired names  
		o - replace LOG_FILE by any other desired textual log file path(must exist)  
		o - replace COUNT_FILE by any temporary file path (it will be created by script)  
		o - define your desired pattern - replace PATTERNS value that is currently defined as array ("error" "warning" "serious"). 
		    It is used to dynamic filtering of log file records. (patterns should be defined in conform to format of "Linux grep tool")  
		    Note that every pattern in the PATTERNS array will correspond to one column in the dashboard report table.  
		    Moreover, the name of monitor will be ended by checksum of patterns string, therefore every time when you change the patterns, the new monitor instance will be created.  

That's all. Now you can click on start.sh to run your custom log-file monitor.  

#### Retrieving data from Monitis

You can also get the monitored data from Monitis by using the following command

        lmon_getdata.sh -d <number of days to get data for> -p <directory path to storing data-files> -f <file name prefix> -m <monitorID>

Whole parameters set is optional. So, if no any parameters are defined, it will get data for current day only and put them into file with prefix of monitor-name.

