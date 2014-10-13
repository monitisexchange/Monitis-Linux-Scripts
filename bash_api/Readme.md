## Monitis Bash API

The current project represents the Bash script implementation of Monitis Custom Monitor Approach.  
Please note that current implementation uses the Monitis latest multi-values approach that allow to send few sets of measurement values at same time.  
Moreover, this approach allows to apply some simple aggregation functionality like sum, average and even choose one of values set to view on your Monitis dashboard.  
It wraps the current [Monitis Open API](http://new.monitis.com/api/api.html) functionality which is necessary to build any custom monitor.  

The Repository contains the following files  

    Monitis Open API wrapper  

        monitis_api.sh          monitis API wrapper functions  
        monitis_constant.sh     monitis api wrapper constants (and configuration)  
        monitis_global.sh       monitis api wrapper global variables  
        monitis_util.sh         monitis api wrapper utility functions  

    Additional part  

        ticktick.sh           JSON processing library
        monitor_getdata.sh    Retriev data from Monitis

    Processing part  

        monitor_start.sh      Main executable script
        monitor_controller.sh start/stop/restart monitor as a deamon processes (for production use)

    Test part  

        monitor_constant.sh    monitor specific constants
        monitor.sh             custom monitor implementation

#### Usage 
To use existing scripts you need to do some additions and changes that will correspond your account and data

  - in monitis_constant.sh  
      - replace _ApiKey_ and _SecretKey_ by your keys values (can be obtained from your Monitis account)  
        
  - in monitor_constant.sh  
      - replace MONITOR_NAME, MONITOR_TAG and MONITOR_TYPE by your desired names  
      - replace RESULT_PARAMS and ADDITIONAL_PARAMS strings by data formats definition of your monitor  
      - you can also add some additional parameters that have to use your script  
      - you may do also definition of DURATION between measurements and sending results (currently it is declared as 5 min)
        
  - replace _monitor.sh_ by your measuring script. Please take into account the following  
      - script should contain function named _get_measure()_
      - the _get_measure()_ will be called periodically. It should fill _return_value_ parameter which consists of two parts:
          - fixed part that should correspond to definition for  RESULT_PARAMS in the _monitor_constants.sh_ 
          - dynamic part that should correspond to definition for ADDITIONAL_PARAMS in the _monitor_constants.sh_ 
              - both parts should be joined into one sending bunch and so the ADDITIONAL_PARAMS should have a key _additionalResults_
              - please note also that _additionalResults_ value should be in form JSONArray with values as JSONObject like __{key:value}__  
          where definition of _key_ is given in monitor_constant.sh as ADDITIONAL_PARAMS variable.  
          you can add so many members in the JSONArray as you wish. Every member will be shown as a new row in the Dashboard view.
       - besides, this script should returning standard _return code_. As usually, 0 mean successful processing.


That's all. Now you can run __monitor_start.sh__ and monitoring process will be started.  

Please note that you can run __monitor_start.sh__ script with command line parameters which allow  
to tune monitor without doing changes in the __monitor_constant.sh__ script.  

        monitor_start.sh -d <duration in min>

#### Usage monitor as a daemon process
Quite often it is necessary to run the monitor as a daemon process to avoid its stopping when your session is closed.  

To do so the __monitor_controller.sh__ script is added into the scripts bunch.  
Use the following pattern to use it  

        monitor_controller.sh [command]

where allowed commands: __start__ (default); __stop__; __restart__.

#### You can also getting monitoring data from monitis 
To do so you should use __monitor_getdata.sh__ script by following pattern  

        monitor_getdata.sh -d <number of days to get data for> -p <folder path to storing data-files> -f <file name prefix> -m <monitor id> 

        where
            -d parameter specifies how many days data do you want to get (default value is 1 day)
               NOTE: each day's data will be stored in the separate files
            -p parameter specifies the directory which will keep the data-files to (by default it is current directory)
            -f parameter specifies the prefix for file name which will contain data (by default it is monitor name defined in monitor_constats.sh)
            -m monitor registration ID 

Notice that all parameters are optional.  
The monitor registration ID should be specified in extreme situation only, e.g. if you have several monitors with same name or some monitor was deleted by accidentally but its data is very important.  

#### Testing 
To check the correctness of Bash API workability, the simple test is provided.  
It consist of two scripts:  

        monitor_constant.sh    monitor specific constants
        monitor.sh             simplest custom monitor implementation

The test monitor is very simple - it generates random integers in range (0 - RANGE).  
The status of data will be OK in case of generated integer less than THRESHOLD. Otherwise, it will generate NOK status.  

<a href="http://imgur.com/"><img src="http://i.imgur.com/TDXyOa8.png" title="FTP monitoring test" /></a>

Naturally, you can view the graph representation of measured data

<a href="http://i.imgur.com/"><img src="http://i.imgur.com/u8TokoA.png" title="FTP monitoring test" /></a>

Double-clicking on any line lead to alternate view which shows additional data about FTP server state at problematic time.  

<a href="http://i.imgur.com/"><img src="http://i.imgur.com/iOacyVA.png" title="FTP monitoring test" /></a>

To get more detailed information you can look  how are implemented one of specific custom monitors:  
    [FTP-monitor](https://github.com/monitisexchange/Monitis-Linux-Scripts/tree/master/FTP-monitor), [Log-Files-Monitor](https://github.com/monitisexchange/Monitis-Linux-Scripts/tree/master/Log-Files-Monitor), [Process-monitor](https://github.com/monitisexchange/Monitis-Linux-Scripts/tree/master/Process-monitor), etc.  



