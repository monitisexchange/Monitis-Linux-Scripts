## The Monitis Node.js servers monitor

The current project is representing the implementation of Monitis custom monitor approach that evaluates the health state of Node.js servers. 
It is composed of two part   

* JavaScript plugin for Node.js server 
* bash script that periodically connects to  Node.js server Monitor plugin, receives, process and sends measured parameters of server 
and evaluation of server health status into Monitis via the Monitis open API. 

Since Node.js itself doesn't contain the embeded stats module we had to create the plugin part that accumulates some pure statistics 
and sends it via HTTP channel by request.  
The script part provides the main processing, packing and sending information to the Monitis main server.  
Because the plugin is implemented by using events-driven technology and only just collecting the information, 
it adds in fact an insignificant additional load to the monitored server and practically don't affect on server performance 
(the main processing is done in remote script part).  
The main purpose of current project is to show the possible way of using Monitis Open API for monitoring Node.js servers. 
Naturally, a different variations of the presented code can be made in accordance user needs. 
The current project presents only one from many possible solutions.

Generally, this monitor architecture can be depicted as the following 

<a href="http://imgur.com/dTsBi"><img src="http://i.imgur.com/dTsBi.png" title="Node server monitoring" /></a>

#### The momitor plug-in collects the following parameters

The whole set of measured parameters divided on two parts  

- fixed that can be defined beforehand  

    1. Status - the evaluation of monitored server health (OK|DOWN|IDLE)
    1. Uptime - measure of time from a last server restarting without any downtime.  
    1. Response Time
          - Average Response Time (avr_resp) - an evaluation of server average time which has been spent to processing of requests during monitoring poll in sec
          - Maximal Response Time (max_resp) - server max time which has been spent to processing of requests during monitoring poll in sec
          - Average Network Time (avr_net) - an evaluation of server average time which has been spent to receive request body from network during monitoring poll in sec 
          - Maximal Network Time (max_net) - server max time which has been spent to receive request body from network during monitoring poll in sec 
          - Average Total Response Time (avr_total) - an evaluation of server average time which has been spent to prepare response during monitoring poll in sec
          - Maximal Total Response Time (max_total) -  server max time which has been spent to prepare response during monitoring poll in sec
    1. The throughput of server (kbps) during monitoring time
          - the input throughput (in_kbps)
          - the output throughput (out_kbps)
    1. The server processing time (active) - the percentage of busy time of server (real processing time) during monitoring time
    1. The server load (load) - the evaluation of number of requests per second during monitoring time.  
    
    1. The Requests count (reqs) - the quantity of requsts which are receiving server during monitoring time.  
    1. The response time of server for requests during monitoring time
          - the average response time 
          - the maximum response time
  

- flexible part that mostly has not so fixed format and can be changing time by time  

    1. The HTTP response codes (codes) - the collecting status codes shown in form {1xx: value, 2xx: value, 3xx: value, 4xx: value, 5xx: value}  
    1. The count of POST requests (post) - the percentage of POST request quantity with respect to the total number of requests during monitoring time.  
    1. The count of successfully processed requests (2xx) - the percentage of request quantity responded by 2xx status code with respect to the total number of requests during monitoring time.
    1. The application specific parameters (e.g. client platform, client application version and so on).  
    1. The monitoring time (mon_time) - the measuring poll time which is the duration between points of sending accumulated data.  
    1. The listen ports of servers (list) - the ports on Node server that are under monitoring.  

#### Customizing and Usage
##### The activation of monitor pluging can be done very easily   
You need to add the following two lines in your code  

        var monitor = require('monitor');// insert monitor module-plugin
        ....
        monitor.Monitor(server);//add server to monitor

Beginning this time the monitor will be collecting the measuring data and sending them by HTTP request that should correspond to the following pattern.  

        http://127.0.0.1:10010/node_monitor?action=getdata&access_code=<access code>
 
    where  
        10010 - the listen port of monitor plugin  
        'node_monitor' - the pathname keyword  
        'action-getdata' - command for getting collected data  
        'access_code' - the specially generated access code that is changing for every session  

Please notice that monitor plugin for security reason currently listen localhost only   

##### You should start monitor shell script firstly
It will periodically ask node server plugin for measured data. 
If Node server doesn't start yet or down the script will send corresponding information to the monitis. 
As soon as Node server will be available the measured info will grabbing and sending to the monitis.
 
To use existing scripts you will need to do some changes which correspond your account and data

* in monitis_constant.sh  
  
  * replace ApiKey and SecretKey by your keys values (can be obtained from your Monitis account)
         
* in monitor_constant.sh 
  * replace MONITOR\_NAME, MONITOR\_TAG and MONITOR\_TYPE by your desired values
  * replace MON\_SERVER string by your server IP address (it is necessary for title only)
  * you may do also definition of DURATION between sending results (currently it is declared as 5 min)
  * replace RESULT\_PARAMS and ADDITIONAL\_PARAMS strings (strongly not recommended because you have to change the plugin code also)
        
That's all. Now you can run __nmon_start.sh__ and monitoring process will be started.

#### Dependencies
There aren't any dependencies for monitor plugin.  
The shell script use __curl__ package to provide HTTP access to the Monitis server and monitor plugin.  

#### Testing 
To check the correctness of monitor workability, the Node test-servers are included in the package.  
So, you can start Node server by command  

        node ./test/test.js

This will listening on two ports - HTTPS (8443) and HTTP (8080). The both are under monitoring.  
  
<a href="http://imgur.com/k6qaP"><img src="http://i.imgur.com/k6qaP.png" title="Node server monitoring test" /></a>

Double-clicking on any line can be switching fixed (tabular view) to the flexible one.  

<a href="http://imgur.com/JiRBX"><img src="http://i.imgur.com/JiRBX.png" title="Node server monitoring test" /></a>

You can also see the grafical view for any numerical values.  

<a href="http://imgur.com/YIZIc"><img src="http://i.imgur.com/YIZIc.png" title="Node server monitoring test" /></a>

It can be noticed that the testing Node server is alive and have quite good state.  



