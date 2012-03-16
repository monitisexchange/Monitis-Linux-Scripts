## The Monitis Node.js servers monitor

  The current project is representing the implementation of Monitis custom monitor approach that evaluates the health state of Node.js servers. It is composed of two part - javascript plugin for Node.js server and bash script that periodically connects to  Node.js server Monitor plugin, receives, process and sends measured parameters of server and evaluation of server health status into Monitis via the Monitis open API. Since Node.js itself doesn't exist the embeded stats module we had to create the plugin part that accumulates some pure statistics and sends it by HTTP channel by request. The script part provides the main processing, packing and sending information to the Monitis main server. Because the plugin is implemented by using events-driven technology and only just collects information, it adds in fact very insignificant additional load to the existing server and practically don't affect on server performance  - the main processing is done in remote script part.
The main purpose of current project is to show the possible way of using Monitis Open API for monitoring Node.js servers. Naturally, a different variations of the presented code can be made in accordance user needs. The current project presents only one from many possible solutions.

The current version can contains some specific custom part for collect which exist in the request header. For instance, the following POST request contains custom part ('mon-platform' and 'mon-version') that can be processed   

     http://127.0.0.1:8080/?get=22&user=simon&key=0898766jwehiweqyhdied823&command=calculate
     mon-platform: linux32
     mon-version: 3.010
     Content-Type: text/x-log
     Filename: /home/monitis/log/queue.log

Generally, this monitor architecture can be depicted as the following 

<a href="http://imgur.com/dTsBi"><img src="http://i.imgur.com/dTsBi.png" title="Node server monitoring" /></a>

#### The momitor plug-in collects the following parameters

Whole set of measured parameters divided on two parts  

- fixed that can be defined beforehand  

    1. Uptime - measure of time from a last server restarting without any downtime.  
    1. The monitoring time (mon_time) - the time between points of sending accumulated data.  
    1. The listen ports of servers (list) - the ports on Node server that are under monitoring.  
    1. The Requests count (reqs) - the quantity of requsts which are receiving server during monitoring time.  
    1. The count of POST requests (post) - the percentage of POST request quantity with respect to the total number of requests during monitoring time.  
    1. The responce time of server for requests during monitoring time
          - the average responce time 
          - the maximum responce time
    1. The throughput of server (kbps) during monitoring time
          - the input throughput (in_kbps)
          - the output throughput (out_kbps)
    1. The count of successfully processed requests (2xx) - the percentage of request quantity responded by 2xx status code with respect to the total number of requests during monitoring time.
    1. The server processing time (active) - the percentage of busy time of server (real processing time) during monitoring time
    1. The server load (load) - the evaluation of number of requests per second during monitoring time.  
  

- flexible that mostly isn't fixed and can be changing time by time  

    1. The status codes (codes) - the collecting status codes shown in form {1xx: value, 2xx: value, 3xx: value, 4xx: value, 5xx: value}  
    1. The application specific parameters (e.g. client platform, client application version and so on).  

#### Customizing and Usage
##### The activation of monitor pluging can be done very easily   
You need to add the following two lines in your code  

        var monitor = require('monitor');// insert monitor module-plugin
        ....
        monitor.Monitor(server);//add server to monitor

Beginning this time the monitor will be collecting the measuring data and sending them by HTTP request that should correspond to the following pattern.  

        http://127.0.0.1:10010/node_monitor?action=getdata&access_code=monitis
 
    where  
        10010 - the listen port of monitor plugin  
        'node_monitor' - the pathname keyword  
        'action-getdata' - command for getting collected data  
        'access_code' - the specially generated access code that is changing for every session  

Please notice that monitor plugin for security reason currently listen localhost only   

##### You should start monitor shell script firstly
It will periodically ask node server plugin for measured data. If Node server doesn't start yed or down script will send corresponding information to the monitis. As Node server will be available the measure will be grabbing and sending to the monitis.
 
To use existing scripts you will need to do some changes that will correspond your account and data

        in monitis_constant.sh 
        - replace ApiKey and SecretKey by your keys values (can be obtained from your Monitis account)
         
        in monitor_constant.sh 
        - replace MONITOR_NAME, MONITOR_TAG and MONITOR_TYPE by your desired names
        - replace RESULT_PARAMS and ADDITIONAL_PARAMS strings by data formats definition of your monitor
        - replace MON_SERVER string by your server IP address (it is necessary for title only)
        - you may do also definition of DURATION between sending results (currently it is declared as 5 mins)
        - optionally you can also change the node server monitor access url - NODE_MONITOR and other constats (strongly no recommended) 
        
That's all. Now you can run __nmon_start.sh__ and monitoring process will be started.

##### You can also getting monitoring data from monitis 
To do so you should use __nmon_getdata.sh__ script by following pattern  

        nmon_getdata.sh -d <number of days to get data for> -p <directory path to storing data-files> -f <file name prefix> -m <monitor id> 

        where
            -d parameter specifies how many days data do you want to get (default value is 1 day)
               NOTE: each day's data will be stored in the separate files
            -p parameter specifies the directory which will keep the data-files to (by default it is current directory)
            -f parameter specifies the prefix for file name which will contain data (by default it is monitor name defined in monitor_constats.sh)
            -m monitor registration ID 

Notice that all parameters are optional.  
The monitor registration ID should be specified in extreme situation only, e.g. if you have several monitors with same name or some monitor was deleted by accidentally but its data is very important.  

After finishing you will see few files named like "_node_data_2012-03-11_"  


#### Dependencies
There are some dependencies for monitor plugin  

   - __log4js__ that is used for write information about  every request into log file  
   - __node_hash__ that is used to generation access code  

The shell script use __curl__ package to provide HTTP access to the Monitis server and monitor plugin.  

#### Testing 
To check the correctness of monitor workability, some Node test-servers are included in the package.  
So, you can start Node server by command  

        node ./test/test.js

It is listening on two ports - HTTPS (8443) and HTTP (8080) which both are under monitor.  
  
<a href="http://imgur.com/k6qaP"><img src="http://i.imgur.com/k6qaP.png" title="Node server monitoring test" /></a>

Double-clicking on any line can be switching fixed (tabular view) to the flexible one.  

<a href="http://imgur.com/JiRBX"><img src="http://i.imgur.com/JiRBX.png" title="Node server monitoring test" /></a>

You can also see the grafical view for any numerical values.  

<a href="http://imgur.com/YIZIc"><img src="http://i.imgur.com/YIZIc.png" title="Node server monitoring test" /></a>

It can be noticed that the testing Node server is alive and have quite good state.  



