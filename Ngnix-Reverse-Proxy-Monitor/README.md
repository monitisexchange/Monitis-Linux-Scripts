## The Nginx reverse proxy monitor

This project presents the Linux Bash-script application that monitoring for Nginx reverse proxy (NRP) health status. It is implemeted as Monitis custom monitor and use the Monitis Open API.  
This project is based on Bash 4.x+ and require the Linux kernel 2.6.x or higher.

#### Content  

    Monitis Open API wrapper

          monitis_api.sh	monitis api wrapper functions  
          monitis_constant.sh	monitis api wrapper constants (and configuration)  
          monitis_global.sh	monitis api wrapper global variables  
          monitis_util.sh	monitis api wrapper utility functions  

    Custom textual log file monitor  

          monitor.sh		custom monitor main part  
          monitor_constant.sh	custom monitor constants (and configuration)  
          nginx_monitor.sh	custom monitor main executor  

    Nginx monitor log file simulator (for testing purpose)  

          log_simulation.sh		log simulator (for testing purpose)  

    Processing part  

      start.sh			runs conveyor that contains log-simulator, monitor and executor
      stop.sh			stops conveyor all parts

#### Dependencies  

The current version of NRP monitor provide HTTP access to the Monitis main server so you have to have installed the __NCURL__ library on Linux  machine where monitor will be run.  
Besides, the monitor uses Linux calculator (named '__bc__') to provide floating points calculations. Thus, you have to have installed Linux calculator too.  
 
#### Used approach

The presented monitor in fact devided on two parts  

     - watching part
     - processing part

The watching part follows for NRP monitor log and accumulates necessary statistics. The processing part periodically reads an accumulated statistics, executes necessary calculations and send them to Monitis main server.  


#### Nginx configuration  

Since Nginx server itself provides not enough statistic for NRP, the current monitor uses the specially configured log file (named as monitor.log file) and provides its watching on the fly to be grabbing of necessary monitoring statistic. The mentioned monitor log file should have the following format  


        <status code>#<responding host address>		e.g.  404#;12.13.11.12:80

To do so, you have to add 2 additional lines in "/etc/ngnix/sites-available/default" config file near the definition of Nginx standard log files in the ngnix server block to define a new log file "monitor.log" like the following


        log_format main '#$upstream_status#;$upstream_addr';    <- definision of new log file format
        access_log /var/log/nginx/monitor.log main;             <- specification of location for new log file


For example, it could be look like this

        server {
                listen       80;
                server_name 10.137.25.110;

                log_format main '#$upstream_status#;$upstream_addr';
                access_log /var/log/nginx/monitor.log main;
                access_log  /var/log/nginx/access.log;
                error_log  /var/log/nginx/error.log;

        }

#### Customizing and Usage 

To use existing scripts you need to do some changes that will correspond your account and data  

	- in monitis_constant.sh 
		- replace ApiKey and SecretKey by your keys values (can be obtained from your Monitis account)  

	- in monitor_constant.sh   
		- replace SERVER_HOST, DEST_HOST_1 and DEST_HOST_2 by your NRP address, destination host 1 and 2 addresses.
		  The specified destinations must be correspond to the ips defined in nginx config e.g. as the following


                    upstream 10.137.25.110 {

                         server www.google.com max_fails=3 fail_timeout=30s;       <- destination host 1
                         server www.yahoo.com max_fails=3 fail_timeout=30s;        <- destination host 2
	
                    }


		- replace MONITOR_TAG and MONITOR_TYPE by your desired names 
		  (MONITOR_NAME is formed authomatically, so you don't need to specify it)

		- replace LOG_FILE with the path specified in ngnix config
		  (in our example it is defined as "/var/log/nginx/monitor.log")
			
		- you can also replace ERR_FILE by any temporary file path (it will be created by script)  

That's all. Now you can click on start.sh to run your custom log-file monitor.  

_Please notice that the start.sh, in addition, starts-up the NRP log simulator (for testing purpose only).  
So, if you want to provide the real monitoring you should comment the corresponding line in the start.sh script to avoid run of simulator._

