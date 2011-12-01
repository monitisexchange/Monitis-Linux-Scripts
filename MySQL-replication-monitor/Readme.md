## The Monitis MySQL replication monitor

  The current project represents the Bash script implementation of Monitis custom monitor approach that evaluate the health state of MySQL Master-Slave replication. It measures remotely some parameters of replication and sends evaluation of health status into Monitis via the Monitis open API.
The main purpose of current project is to show the possible way of using Monitis Open API for monitoring DB replication process. Naturally, a different variations of the presented code can be made in accordance user needs. The current project presents only one from many possible solutions.

  The current version of MySQL replication monitor provide SSL access to the replicating machines so you have to have installed Secure Socket Layer (SSL) binary and related cryptographic tools  (normally openssl) and corresponding SSL shared libraries (as usually libssl) on Linux  machine where monitor will be run. Besides, you have to have in your Linux account the pair of generated access keys. And, of course, you should have account (user) on MySQL servers with enough privileges (ROOT, SUPER or REPLICATION) which will be used by monitor (monitor will execute necessary MySQL command remotely).

<a href="http://imgur.com/cWPMb"><img src="http://i.imgur.com/cWPMb.png" height="80%" title="MySQL replication monitoring" /></a>

#### Monitored parameters

  1. The alive status of replication is evaluated by testing the following expression

        slave_io_running == ‘yes’ && slave_sql_running == ‘yes’

  1. The slave lagging behind master is evaluated by checking seconds_behind_master parameter which shows time difference in seconds between the Slave_SQL thread and the Slave_IO thread for same event. 

  1. The level of desinchronization between master and slave evaluating by following equestion

        desynch = 1 - (master.write.binlog.position/(slave.read.exec_master_log_pos + max_binlog_size *(master.write.binlog.num -  slave.read.master_binlog.num) 

        where 
        - master.write.binlog.position is the position within the master binlog file where master DB writes to
        - slave.read.exec_master_log_pos is the position within the master binlog file where slave DB reads from
        - max_binlog_size is the maximal size of binlog file
        - master.write.binlog.num is the master binlog file number (extension part of binlog file) where is currently writing  master to 
        - slave.read.master_binlog.num is the master binlog file number (extension part of binlog file) which is currently read by slave

        Fine if this parameter value will be near to zero.

  1. The replication rate (progress in positions of master binlog file per second) for master writing and slave reading processes should approximately match and never shouldn't reach down to zero in the normally loaded server.

        Master_load=(master.write.binlog.position-prev_master.write.binlog.position+max_binlog_size*(master.write.binlog.num-prev_master.write.binlog.num))/(current_timestamp-prev_timestamp)
        Slave_load=(slave.read.exec_master_log_pos-prev_slave.read.exec_master_log_pos+max_binlog_size*(slave.read.master_binlog.num-prev_slave.read.master_binlog.num))/(current_timestamp-prev_timestamp)

               where "prev" is the prefix which is mean previous measured data

  1. Also the result of following expression (inconsistency, discord factor) should swing around zero in correct replication process

        discord_factor = 1 - Slave_load / Master_load


 Please notice that the evaluation of replication parameters cannot have absolute precision of measurements in the presented approach because the measurement of replicating databases is provided sequentially (not in parallel). Since every remote measurement takes a while, it is the reason to receiving of  not fully synchronous data. Thus, the final results can have some measurement uncertainties in range about 0.5% - 1%.

#### Customizing and Usage 
To use existing scripts you need to do some changes that will correspond your account and data

        in monitis_constant.sh 
        - replace ApiKey and SecretKey by your keys values (can be obtained from your Monitis account)
        - you may do also definition of DURATION between measurements and sending results (currently it is declared as 60 sec)
        
        in monitor_constant.sh 
        - replace MONITOR_NAME, MONITOR_TAG and MONITOR_TYPE by your desired names
        - replace RESULT_PARAMS and ADDITIONAL_PARAMS strings by data formats definition of your monitor
        - provide the definition of Master and Slave machines and corresponding credentials to access them 
        
That's all. Now you can run __monitor_test.sh__ and monitoring process will be started.

#### Testing 
To check the correctness of monitor workability, some tests was done on real  MySQL 5.0.x replicating Master-Slave configuration that was under real load. The Master and Slave are located in the cloud and has differ IPs.

<a href="http://imgur.com/TM1B4"><img src="http://i.imgur.com/TM1B4.png" title="MySQL replication monitoring test" /></a>

It can be noticed that the replication is alive and have quite good state. The swinging  of discord factor in quite big range can be explained by quite big unstable load on server. The Desync in 1% is usually normal side effect in this case because, as it was explained above, the measurement of the DBs is provided sequentially and this small inadequacy is explained just this fact.


