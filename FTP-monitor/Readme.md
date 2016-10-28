## The Monitis FTP monitor

The current project represents the Bash script implementation of Monitis custom monitor approach that evaluate the health state of FTP server.   
Please note that current implementation uses the Monitis newest multi-values approach that allow to send few sets of measurement values at same time.  
Moreover, this approach allows to apply some simple aggregation functionality like sum, average and even choose one of values set to view on your Monitis dashboard.  
It wraps the Monitis updated Open API functionality.  

The Repository contains the following files  

    Monitis Open API wrapper  

        monitis_api.sh          monitis API wrapper functions  
        monitis_constant.sh     monitis api wrapper constants (and configuration)  
        monitis_global.sh       monitis api wrapper global variables  
        monitis_util.sh	monitis api wrapper utility functions  

    Custom FTP server monitor  

        ftp_check.sh           FTP custom monitor implementation
        monitor_constant.sh    FTP monitor constants
        test                   Text file for testing
        down                   Download control script
        up                     Upload control script

    Processing part  

        fmon_start.sh         Main executable script
        monitor_controller.sh start/stop/restart FTP monitor as a deamon processes (for production use)

    Additional part  

        ticktick.sh           JSON processing library
        fmon_getdata.sh       Retriev data from Monitis script


#### Dependencies
The current version of FTP monitor provide FTP access to the FTP server so you have to have installed the __cURL__ tool on Linux  machine where monitor will be run.  

#### Monitored parameters

The FTP monitor provides the following steps:
  - connect to FTP server and get list of files from specified folder
  - upload test file
  - download test file
  - delete test file on FTP server
  - get list of file and compare it with origin one

Based on above mentioned steps results the FTP monitor prints out the following metrics - action, code, size, time_total, time_connect, time_transfer, speed

  - Pprovided action (upload or download)   
  - The resulting FTP response code for fulfilling action 
  - The size of transfer [bytes]  
  - The total time of transfere [seconds]  
  - The time to connect to the FTP server [seconds]  
  - The time spent to transfer [seconds]  
  - The speed (throghput) of transfer [bytes/sec]  

The health status of FTP can be evaluated by provided [FTP response codes](http://www.theegglestongroup.com/writing/ftp_error_codes.php)    

If you want to test it,  
you have to have firstly the account in the Monitis,   
next, make customization of scripts like it described below.

#### Customizing and Usage 
To use existing scripts you need to do some changes that will correspond your account and data

  - in monitis_constant.sh  
      - replace ApiKey and SecretKey by your keys values (can be obtained from your Monitis account)  
        
  - in monitor_constant.sh  
      - replace HOST, USER, PASSWD and FOLDER according your FTP engine parameters and your credentials
      - replace MONITOR_NAME, MONITOR_TAG and MONITOR_TYPE by your desired names (optional)
      - replace RESULT_PARAMS and ADDITIONAL_PARAMS strings by data formats definition of your monitor  
       (not recommended because you will be needed to correct correspondingly some functions body in few scripts)
      - you may do also definition of DURATION between measurements and sending results (currently it is declared as 5 min)
        
That's all. Now you can run __fmon_start.sh__ and monitoring process will be started.  

Please note that you can run __fmon_start.sh__ script with command line parameters which allow  
to tune monitor without doing changes in the __monitor_constant.sh__ script.  

        fmon_start.sh -d <duration in min>

#### Usage monitor as a daemon process
Quite often it is necessary to run the monitor as a daemon process to avoid its stopping when your session is closed.  

To do so the __monitor_controller.sh__ script is added into the scripts bunch.  
Use the following pattern to use it  

        monitor_controller.sh [command]

where allowed commands: __start__ (default); __stop__; __restart__.

#### You can also getting monitoring data from monitis 
To do so you should use __fmon_getdata.sh__ script by following pattern  

        mmon_getdata.sh -d <number of days to get data for> -p <directory path to storing data-files> -f <file name prefix> -m <monitor id> 

        where
            -d parameter specifies how many days data do you want to get (default value is 1 day)
               NOTE: each day's data will be stored in the separate files
            -p parameter specifies the directory which will keep the data-files to (by default it is current directory)
            -f parameter specifies the prefix for file name which will contain data (by default it is monitor name defined in monitor_constats.sh)
            -m monitor registration ID 

Notice that all parameters are optional.  
The monitor registration ID should be specified in extreme situation only, e.g. if you have several monitors with same name or some monitor was deleted by accidentally but its data is very important.  

After finishing you will see few files named like "_FTP_10.37.125.50:11211_2012-03-15.log_"  

#### About FTP check script

The __ftp_check.sh__ script runs in standalone mode and puts a measurement data into _sysout_ stream.  
So, the calling application should grab the data just from _sysout_.  
This script should be called with few parameters like depicted below  

        { -h | --host | -host }                    - FTP server IP address
        { -u | --user | -user }                    - User name
        { -p | --password | -password }            - User password
        { -d | --remote_folder | -remote_folder }  - Remote folder
        { -t | --timeout | -timeout }              - Maximum duration [seconds] allowed for the transfer processing
        { -o | --mode | -mode }                    - one of {DEBUG | PLUGIN | CUSTOM} 
        { -m | --metrics | -metrics }              - the full set of subset of "[action, code, size, time_total, time_connect, time_transfer, speed]"

Note that {bracketed expression}  means - must be chosen one of enumerated values, [bracketed expression] means - can be chosen one of enumerated values (aka optional).  
In case when any parameter contains witespace symbols this parameter should be enclosed in the quotation marks (").  
The "CUSTOM" mode forces to work the script in custom monitor mode which prints out the output in format that require just Monitis API  

        paramName1:paramValues1[;paramName2:paramValues2...] 

The PLUGIN (and DEBUG) mode forces to work the script in mode which prints out the output in format that require Monitis plugable agent  

        paramName1=paramValues1[ paramName2=paramValues2...] 

NNote that the _paramValues_ data should be enclosed in the [brackets] like it is done for JSON array.  

As an example you can see the command bellow  

        ftp_check.sh -h "98.139.183.24" -u "user" -p "123456" -d "MyFiles" -t 20 --m "[action, code, size, time_total, time_connect, time_transfer, speed]" -o DEBUG

which means - check FTP server health defined by IP address (98.139.183.24), using user credential (user/123456). Access to folder (MyFiles). Timeout for any operation is limited by 20 sec. Prepare print out for metrics (action, code, size, time_total, time_connect, time_transfer, speed) and works in DEBUG mode which means to print aditional debug info.


#### Testing 
To check the correctness of monitor workability, some tests was done on public FTP.  

<a href="http://i.imgur.com/IOChc"><img src="http://i.imgur.com/IOChc.png?1" title="FTP monitoring test" /></a>

Naturally, you can view the graph representation of measured data

<a href="http://i.imgur.com/a9xgR"><img src="http://i.imgur.com/a9xgR.png?1" title="FTP monitoring test" /></a>

Double-clicking on any line lead to alternate view which shows additional data about FTP server state at problematic time.  

<a href="http://i.imgur.com/M1Ovo"><img src="http://i.imgur.com/M1Ovo.png?1" title="FTP monitoring test" /></a>

<a href="http://i.imgur.com/Jh9jM"><img src="http://i.imgur.com/Jh9jM.png?1" title="FTP monitoring test" /></a>

Thus, we have the wrong credentials of user at that time (sure, it was artificially created).  


