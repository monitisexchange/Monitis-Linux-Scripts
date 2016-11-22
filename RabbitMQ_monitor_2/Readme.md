## The Monitis RabbitMQ monitor

The current project represents the Bash script implementation of Monitis custom monitor approach that evaluate the health state of RabbitMQ engine.  
It wraps the [Monitis Open API](http://monitis.com/api/api.html) functionality.
In contrast of [previous implementation of RabbitMQ monitor](https://github.com/monitisexchange/Monitis-Linux-Scripts/tree/master/RabbitMQ_monitor), the current implementation represents the multivalue monitor concept, where control/master metric is the queue name.

The Repository contains the following files

        Readme.md
        monitor
          monitis_api.sh         Monitis API wrapper implementation
          monitis_util.sh        Utilities function set
          monitis_global.sh      Monitis API wrapper global variables
          monitis_constant.sh    Monitis API constants
          rabbitmq_monitor.py    RabbitMQ custom monitor implementation
          monitor_constant.sh    RabbitMQ monitor constants
          rmqmon_start.sh        Main executable script
 
#### Dependencies
The current version of RabbitMQ monitor provide TCP access to the RabbitMQ server so you have to have installed the __cUrl__ on Linux  machine where monitor will be run.  
Besides, the monitor uses Linux calculator (named '__bc__') to provide floating points calculations. Thus, you have to have installed Linux calculator too.  

#### RabbitMQ preparation
First you have to install RabbitMQ server. Easiest way is to install it from __dep__ package by following command

        sudo dpkg -i rabbitmq-server_3.6.6_1_all.deb

The latest version can be downloaded from [original RabbitMQ site](http://www.rabbitmq.com/install-debian.html)  
Please NOTE that RabbitMQ requires the latest version of Erlang (at least version R18).  
Thus, during install of RabbitMQ you can get warning message about unresolved dependencies.  
Try to use the following command to resolve this issue   

        sudo apt-get update
        sudo apt-get -f install

To provide monitoring of RabbitMQ server you have to enable [RabbitMQ Management HTTP API](http://hg.rabbitmq.com/rabbitmq-management/raw-file/rabbitmq_v2_8_6/priv/www/api/index.html).  
It allow to get necessary information by using REST technology.  
The management plugin is included in the RabbitMQ distribution since version 2.8.1. To enable it, use the following command:

        sudo rabbitmq-plugins enable rabbitmq_management

For older version you have to install this plugin separately.  
That's all. Now you can use the following RabbitMQ server command

        sudo /etc/init.d/rabbitmq-server {start|stop|status|rotate-logs|restart|condrestart|try-restart|reload|force-reload}

More detailed information can be found in the [RabbitMQ site](http://www.rabbitmq.com/).


#### Monitored parameters

The current implementation of RabbitMQ monitor measures the following metrics
  - name - The queue name
  - state - The running state of queue
  - consumers - Number of consumers connected to the queue
  - memory - Amount of memory in use by the queue
  - msg_ready - Count of messages in the queue ready for conuming
  - msg_unack - Count of messages in the queue consummed but not acknowleged yet
  - msg_total - Total Count of messages yet kept in the queue 
  - rate_in - The average rate for measurement interval of messages published into queue.
  - rate_get - The average rate for measurement interval of messages delivered in acknowledgement mode to consumers. 
  - rate_ack - The average rate for measurement interval of messages acknowledged in the queue.

The state 'FAIL' is generated when RabbitMQ server unavailable for some reason.  

If you want to test it, you have to have firstly the account in the [Monitis](http://www.monitis.com) or {its free mirror](http://www.monitor.us),   
next, make customization of scripts like it described below.  

#### Customizing and Usage 
To use existing scripts you need to do some changes that will correspond your account and data

  1. in monitis_constant.sh   

        - replace ApiKey and SecretKey by your keys values (can be obtained from your Monitis account)
        
  1. in monitor_constant.sh   

        - replace HOST and PORT according your RabbitMQ server access parameters
        - replace NAME, MONITOR_TAG and MONITOR_TYPE by your desired names (optional)
        - replace RESULT_PARAMS and ADDITIONAL_PARAMS strings by data formats definition of your monitor  
          (not recommended because you will be needed to correct correspondingly the 'get_measure' function body)
        - you may do also definition of DURATION between measurements and sending results (currently it is declared as 60 sec)
        
That's all. Now you can run __rmqmon_start.sh__ and monitoring process will be started.  
Note: to demonize use the foloowing command  

        nohup ./rmqmon_start.sh &

#### Testing 
To check the correctness of monitor workability, some tests was done on working RabbitMQ server which was under real load.  

<a href="http://i.imgur.com/yLO6JEg.png"><img src="http://i.imgur.com/yLO6JEg.png" title="RabbitMQ monitoring test" /></a>

The graphical mode view is also available.  

<a href="http://i.imgur.com/JimtYDa.png"><img src="http://i.imgur.com/JimtYDa.png" title="RabbitMQ monitoring test" /></a>




