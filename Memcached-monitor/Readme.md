## The Monitis Memcached monitor

The current project represents the Bash script implementation of Monitis custom monitor approach that evaluate the health state of Memcached engine. 
It wraps the Monitis Open API functionality.

The Repository contains the following files

        Readme.md
        monitor
          monitis_api.sh         Monitis API wrapper implementation
          monitis_util.sh        Some utilities 
          monitis_global.sh      Monitis API wrapper global variables
          monitis_constant.sh    Monitis API constants
          memcached_monitor.sh   Memcached custom monitor implementation
          monitor_constant.sh    Memcached monitor constants
          mmon_start.sh          Main executable script

#### Dependencies
The current version of Memcached monitor provide TCP access to the engine so you have to have installed the NetCat library (usually named 'nc') on Linux  machine where monitor will be run.  
Besides, the monitor uses Linux calculator (named 'bc') to provide floating points calculations. Thus, you have to have installed Linux calculator too.  

#### Monitored parameters

The Memcached monitor measures the following metrics

  - Percent of open connections to max connections   
    (conns = curr_connections / maxconns)
  - Percent of items that have been requested and not found to total number of get commands  
    (get_miss = get_misses / (get_hits + get_misses))
  - Percent of items that have been requested to delete and not found to total number of delete commands  
    (delete_miss = delete_misses / (delete_hits + delete_misses))
  - Percent of items that have been requested to increase and not found to total number of increase commands  
    (incr_miss = incr_misses / (incr_hits + incr_misses))
  - Percent of items that have been requested to decrease and not found to total number of decrease commands  
    (decr_miss = decr_misses / (decr_hits + decr_misses))
  - Percent of current number of bytes used to store items to the max accessible bytes  
    (mem_usage = bytes / limit_maxbytes)
  - Percent of valid items removed from cache to free memory to current number of items stored  
    (evictions = evictions / curr_items)  
  - Average value for requests per second
    (reqs = (get_hits +  get_misses) / evaluation_period)  
  - The inbound throughput value estimated in Kbytes per second  
    (in_kbps = bytes_written / evaluation_period)  
  - The outbound throughput value estimated in Kbytes per second  
    (out_kbps = bytes_read / evaluation_period)  
  - The Memcached uptime (duration since the server last (re)started)  


The health status of Memcached is evaluated as 'FAIL' when it is detected at least one of below listed events  

  - The percent of open connections (conns) exceed 95%  
  - The percent of items that have been requested and not found (get_miss) exceed 5%  
  - The percent of items that have been requested to delete and not found (delete_miss) exceed 10%  
  - The percent of items that have been requested to increase and not found (incr_miss) exceed 5%  
  - The percent of items that have been requested to decrease and not found (decr_miss) exceed 5%  
  - The Percent of current number of bytes used to store items (mem_usage) exceed 95%  
  - The Percent of valid items removed from cache to free memory to current number of items stored (evictions) exceed 5%  

If you want to test it,  
you have to have firstly the account in the Monitis,   
next, make customization of scripts like it described below.

#### Customizing and Usage 
To use existing scripts you need to do some changes that will correspond your account and data

        in monitis_constant.sh 
        - replace ApiKey and SecretKey by your keys values (can be obtained from your Monitis account)
        
        in monitor_constant.sh 
        - replace MEMCACHED_HOST and MEMCACHED_PORT according your memcached engine parameters
        - replace MONITOR_NAME, MONITOR_TAG and MONITOR_TYPE by your desired names (optional)
        - replace RESULT_PARAMS and ADDITIONAL_PARAMS strings by data formats definition of your monitor  
          (not recommended because you will be needed to correct correspondingly the 'get_measure' function body)
        - you may do also definition of DURATION between measurements and sending results (currently it is declared as 60 sec)
        
That's all. Now you can run __monitor_start.sh__ and monitoring process will be started.

#### Testing 
To check the correctness of monitor workability, some tests was done on working Memcached (1.4.7) which was under real load.  

<a href="http://i.imgur.com/pdOw2"><img src="http://i.imgur.com/pdOw2.png" title="Memcached monitoring test" /></a>

Double-clicking on any line lead to alternate view which shows additional data about Memcached state at that moment.  

<a href="http://i.imgur.com/LazBD"><img src="http://i.imgur.com/LazBD.png" title="Memcached monitoring test" /></a>

It can be noticed that the Memcached engine is alive and have quite good state. 


