## The Nginx Bash monitor

This project presents the Linux Bash-script application that monitoring the Nginx reverse proxy (NRP) health status.  
Please note that the same approach can be easily used for monitoring of any Nginx instance independently on role it play (balancer, HTTP server, etc.).  
It is implemeted as Monitis custom monitor and use the Monitis Open API.  
This project is based on Bash 4.x+ and require the Linux kernel 2.6.x or higher.

#### Content  

   Monitis Open API wrapper  

          monitis_api.sh        monitis api wrapper functions  
          monitis_constant.sh   monitis api wrapper constants (and configuration)  
          monitis_global.sh     monitis api wrapper global variables  
          monitis_util.sh       monitis api wrapper utility functions  

   Custom NRP monitor  

          monitor.sh            custom monitor main part  
          monitor_constant.sh   custom monitor constants (and configuration)  
          nginx_monitor.sh      custom monitor main executor  

   Service part  

          start.sh              runs conveyor that contains monitor and executor
          stop.sh               stops conveyor all parts

#### Dependencies  

The current version of NRP monitor provide HTTP access to the Monitis main server so you have to have installed the __CURL__ library on Linux  machine where monitor will be run.  
Besides, the monitor uses Linux calculator (named '__bc__') to provide floating points calculations. Thus, you have to have installed Linux calculator too.  
 
#### Used approach

The possibilities for getting statistics from Nginx are very limited, but fortunately, it has a powerful feature to configure a log file.  
This makes it possible to create necessary statistics by configuring the log file and then watching and grabbing the monitoring data from it.  
The presented monitor in fact devided on two parts  

   - watching part
   - processing part

The watching part follows for Nginx server log and accumulates necessary statistics.  
The processing part periodically reads an accumulated statistics, executes necessary calculations and send them to Monitis main server.  

<a href="http://blog.monitis.com/"><img src="http://blog.monitis.com/wp-content/uploads/2012/06/NRP_Monitoring.png" title="Nginx monitoring" /></a>

The current monitor calculates and shows the following metrics:

  1. The input load to NRP (in_load)  
    The number of requests which were received, divided by the observation time

  1. The load redirected to destination host 1 (out1_load)  
    The number of requests redirected to destination host 1, divided by the observation time

  1. The load redirected to destination host 2 (out2_load)  
    The number of requests redirected to destination host 2, divided by the observation time

  1. The percentage of requests which  were redirected to destination host 1 (out1_reqs)  

  1. The percentage of requests which  were redirected to destination host 2 (out2_reqs)  

  1. The percentage of successfully processed requests by destination host 1 (out1_2xx)  
    The number of responses with a successful status code (2xx) relative to the total number of requests to destination host 1

  1. The percentage of successfully processed requests by destination host 2 (out2_2xx)  
    The number of responses with a successful status code (2xx) relative to the total number of requests to destination host 2

  1. The common estimation of NRP state (status)  
     OK – normal working state  
     IDLE – idle state (don’t receive any requests)  
     DEAD – NRP is down (Nginx process isn’t found)  

_Notice that metrics 4 and 5 show the real distribution of requests between destination hosts. Their sum always should equal 100%._

#### Nginx configuration  

Since Nginx server itself provides not enough statistic, the current monitor uses the specially configured log file (named as monitor.log file)  
and provides its watching on the fly to be grabbing of necessary monitoring statistic. The mentioned monitor log file should have the following format  


        <status code>#<responding host address>		e.g.  404#;12.13.11.12:80

To do so, you have to add 2 additional lines in "/etc/ngnix/sites-available/default" config file near the definition of Nginx standard log files  
in the Ngnix server block to define a new log file "monitor.log" like the following  

        log_format main '$upstream_status#;$upstream_addr';    <- definision of new log file format
        access_log /var/log/nginx/monitor.log main;             <- specification of location for new log file


For example, it could be look like this  

        server {
                listen       80;
                server_name 10.137.25.110;

                log_format main '$upstream_status#;$upstream_addr';
                access_log /var/log/nginx/monitor.log main;
                access_log  /var/log/nginx/access.log;
                error_log  /var/log/nginx/error.log;
                ...
        }

#### Customizing and Usage 

To use existing scripts you need to do some changes that will correspond your account and data  

   - in monitis_constant.sh  
       - replace ApiKey and SecretKey by your keys values (can be obtained from your Monitis account)  

   - in monitor_constant.sh   
       - replace SERVER_HOST, DEST_HOST_1 and DEST_HOST_2 by your NRP address, destination host 1 and 2 addresses.  
         The specified destinations must be correspond to the ips defined in nginx config e.g. as the following


                    upstream 10.137.25.110 {
                         ...
                         server www.google.com max_fails=3 fail_timeout=30s;       <- destination host 1
                         server www.yahoo.com max_fails=3 fail_timeout=30s;        <- destination host 2
                         ...
                    }


       - replace MONITOR_TAG and MONITOR_TYPE by your desired names (optional)   
         (MONITOR_NAME is formed authomatically, so you don't need to specify it)

       - replace LOG_FILE with the path specified in ngnix config  
         (in our example it is defined as "/var/log/nginx/monitor.log")
			
       - you can also replace ERR_FILE by any temporary file path  
         (it will be created by script)  

That's all. Now you can click on start.sh to run your custom Nginx monitor.  

#### NRP monitor test

The simplest configuration was chosen for testing of the reverse proxy.  
Two destination hosts were simulating responses by generating random status codes with normal probability distribution  
and with mean value – 2xx successful code. The input load was generated by an HTTP generator which provided a load on NRP of about 1 request per second.  

NRP was tuned to round-robin distribution so that the input load should have been distributed equally between the designated hosts.  
As result we got the following monitoring table in our Monitis account:

<a href="http://blog.monitis.com/"><img src="http://blog.monitis.com/wp-content/uploads/2012/06/NRP_Monitoring2.png" title="Nginx monitoring" /></a>

Notice that during the test the NRP was restarted. The monitor detected this and marked it as NRP DEAD status.  
Double-clicking on any line will show more detailed additional information:  

<a href="http://blog.monitis.com/"><img src="http://blog.monitis.com/wp-content/uploads/2012/06/NRP_Monitoring3.png" title="Nginx monitoring" /></a>

Double-clicking on the DEAD status line shows the following:

<a href="http://blog.monitis.com/"><img src="http://blog.monitis.com/wp-content/uploads/2012/06/NRP_Monitoring4.png" title="Nginx monitoring" /></a>


