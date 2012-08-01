## The MySQL monitor ##

The current project represents the Bash script implementation of Monitis custom monitor approach that evaluate the health state of MySQL server.  
It measures locally some parameters of MySQL and sends evaluation of health status into Monitis via the Monitis open API.  
The main purpose of current project is to show the possible way of using Monitis Open API for monitoring DB behavior. Naturally, a different variations of the presented code can be made in accordance user needs.  
This project is based on Bash 4.x+ and require the Linux kernel 2.6.x or higher.

#### Content  

    Monitis Open API wrapper

          monitis_api.sh        monitis api wrapper functions  
          monitis_constant.sh   monitis api wrapper constants (and configuration)  
          monitis_global.sh     monitis api wrapper global variables  
          monitis_util.sh       monitis api wrapper utility functions  

    Custom MySQL monitor  

          mysql_monitor.sh      custom monitor main part  
          monitor_constant.sh   custom monitor constants (and configuration)  
          monitor_start.sh      custom monitor main executor 
 
    Additional part  

          monitor_getdata.sh    module for getting data from Monitis
          ticktick.sh           JSON engine for bash

#### Measuring parameters

The current MySQL monitor measures the following parameters  

   - receive - The number of Kbytes received from all clients
   - send - The number of Kbytes sent to all clients
   - insert - Count of INSERT executed commands
   - select - Count of SELECT executed statements 
   - update - Count of UPDATE executed commands
   - delete - Count of DELETE executed commands
   - queries - The number of statements executed by the server
   - slow_queries - The number of queries that have taken more than __long_query_time__ seconds.
   - thread_running - The number of threads that are not sleeping
   - connections_usage - The percentage of used connections with respect to the maximum allowed connections count.
   - status - The evaluation of MySQL healt
      - DEAD - impossible to connect to MySQL server (could be down)
      - IDLE - MySQL server is in idle state
      - SLOW_QUERY - slow queries detected
      - OK - No any errors are detected
 
#### Customizing and Usage 

To use existing scripts you need to do some changes that will correspond your account and data  

  - in monitis_constant.sh  
     - replace _ApiKey_ and _SecretKey_ by your keys values (can be obtained from your Monitis account)
  - in monitor_constant.sh   
     - replace MONITOR_NAME, MONITOR_TAG and MONITOR_TYPE by your desired names  

Please NOTE that the slow queries MySQL tracker should be switched on if you want to monitor for slow queries.

  For MySQL 5.1.6 and above you should enable the slow query logging in MySQL by enter the following command(s)

        set global slow_query_log = 'ON';             <- switching on the MySQL slow queries tracker
        
        set global slow_query_log_file ='/var/log/mysql/slow-query.log';  <- Set the path to the slow query log (optional)

        set global long_query_time = 20;              <- Set the amount of time a query needs to run before being logged (optional; default is 10 seconds)
     
  For MySQL below 5.1.6 to do the following

  - Edit the /etc/my.cnf file with your favorite text editor
  - Add the following line under the “[mysqld]” section. 
     - The path to the log file can be whatever you want, e.g.  
        
        log-slow-queries=/var/log/mysql/slow-query.log

     - Set the amount of time a query needs to run before being logged (default is 10 seconds)  

        long_query_time=20     

  - Restart the MySQL server e.g. by command  

        service mysqld restart

In addition the monitor should be run under user that have credentials which allow to access (read/write) to MySQL _slow.log_ file.  
Alternatively, you can change the MySQL _slow.log_ file permissions so this allow monitor-running user to have (read/write) access.  
Normally, this file is located by default in the /var/lib/mysql folder.  


That's all.  

Now you can run your custom MySQL monitor by using e.g. the following command.  

        monitor_start.sh 1> /dev/null &

It will run it as a daemon process and prints only error messages.




