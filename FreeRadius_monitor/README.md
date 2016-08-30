## Free Radius server monitor (FRMon)

_Original Author: Arthur Sergeyan_

_Review and refactoring: Simon Hunanyan_

This project presents the Linux Bash-script application which monitors [FreeRadius server](http://freeradius.org) health status.  
 It is implemeted as Monitis custom monitor and uses the Monitis Open API.  
The project is based on Bash 4.x+ and requires Linux kernel 2.6.x or higher.

#### Content  

   Monitis Open API wrapper  

          monitis_api.sh        monitis api wrapper functions  
          monitis_constant.sh   monitis api wrapper constants (and configuration)  
          monitis_global.sh     monitis api wrapper global variables  
          monitis_util.sh       monitis api wrapper utility functions  

   Custom FRMon  

          env.sh                verifying the existence of necessary commands
          monitor_constant.sh   custom monitor constants (and configuration)  
          radius_monitor.sh     custom monitor main executor  

   Service part  

          monitor_controller.sh controlling monitor (status, start, stop, restart)
          start.sh              runs conveyor that contains monitor and executor
          stop.sh               stops conveyor all parts

#### Dependencies  

The current version of FRMon provide HTTP access to the Monitis main server so you have to have installed the __CURL__ library on Linux  machine where monitor will be run.  
Besides, the monitor uses Linux calculator (named '__bc__') to provide floating points calculations. Thus, you have to have installed Linux calculator too.  
Also note that the application uses the FreeRadius 'radtest' command to simulate Radius request, thus, you need to have installed the __FreeRadius client__ on the client’s host.
 
#### Used approach

The presented monitor act this way:

   - simulating radius test request 
   - processing requet results 

#### FreeRadius additional configurations  

In order to get this monitor work properly, you should make a test user for Radius.   
Usually, for this you need to edit the /etc/raddb/users (or /etc/freeradius/users) file by adding new user's cridentials.  
For example, by adding the line 

        'testuser  Cleartext-Password := "123456Aa"'

Also you will need to define the client's IP (the IP of the host machine where the FRMon will run).   
For this edit /etc/raddb/clients.conf (or edit /etc/freeRadius/clients.conf) by adding:  

        client testuser {
          ipaddr = 10.137.25.173 # replace by your client's IP
          secret = testing123    # replace by your secret
        }

#### Customizing and Usage 

To use existing scripts you need to do some changes that will correspond your account and data  

   - in __monitis_constant.sh__  

       - replace ApiKey and SecretKey by your keys values (can be obtained from your Monitis account)  

   - in __monitor_constant.sh__   

       - replace TESTUSER with the test user's username, which you have already added to Radius

       - replace TESTPASSWORD with the test user's password, which you have already added to Radius

       - replace SECRET with your Radius secret

       - replace HOST with the Radius carrier host IP

       - if you changed the Radius default port (1812), then replace PORT with the one you have set. Usually no need for change.

		
#### Measured metrics

This applicattion is tracking your Radius server health status by using 2 metris:

   - __status__, which shows the servers current running status.  
      it may have 3 value:

       OK - server is running properly

       NOK - server has problem

       DEAD - server is down  
			
   - __reqTime__, which shows the responce delay in seconds for Radius request.

That's all. Now you can call 'monitor_controller.sh start' to run your custom FRMon monitor.  

