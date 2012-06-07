
## MONITORING MONGO WITH MONITIS ##

Original Author: Brad Carleton
Company: Blue Pines Technologies
Website: http://www.bluepines.org

#### OVERVIEW ####

These scripts allow a user to easily get some monitoring around their Mongo installs using Monitis.

#### DEPENDENCIES ####

__elementtree__ - a python xml library (_http://effbot.org/zone/element-index.htm_)


#### OTHER ####

*You must run mongod with the --rest option enabled.


#### INSTALLATION ####

The following steps are required:

1. Download the monitor code from GitHub - the structure should be the following  

        ../mongo/monitiscred.py
        ../mongo/monitisserver.py
        ../mongo/send_data.py
        ../mongo/setup_mongo_monitors.py
        ../mongo/COPYRIGHT
        ../mongo/README

2. Please make sure that __*.py__ files are executable
3. install MongoDB (if not yet installed)  

        sudo apt-get install mongodb

    3.1. Once installed and run it exposes a http server on port 28017 which can be accessed via browser (_http://127.0.0.1:28017_). The landing page of MongoDB should be displayed.  

    3.2. Try to push link __"List all Commands"__ on the opened page  

    3.3. if you got the answer __"Rest is not enabled..."__ open MongoDB conf file (_/etc/mongobd.conf_) for editing and enable rest by adding __"rest = true"__ line.  

    3.4. Restart the MongoDB e.g by command  

        service mongodb restart

4. Download dependencies - __elementtree__  
    and install it by command  

        sudo python setup.py install

5. Register monitors by command  

        python setup_mongo_monitors.py

    it will register 9 monitors.  

6. Now you can run monitors  

        python send_data.py

    This will send data every time you run it.  
    Set it up with Cron or any other scheduling agent to begin periodically sending data back to Monitis.  
    You can check results in the Monitis dashboard to view your MongoDB Stats.







