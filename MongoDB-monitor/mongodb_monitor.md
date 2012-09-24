__Introduction__

 mongodb_monitor.xml is a template for Monitis Monitor Manager. 
 It allows to you get statistic data from MongoDB
      
__Install/configure__

Install M3 according it's installation rules.
Be sure you have *mongostat* installed (this tool is coming with MongoDB installation package).
Try *'which mongostat'* to check existence of *mongostat*

__Run__

      Type monitis-m3 /path/to/mongodb_monitor.xml<Return> in the command line.

   *Important notice:* After each run monitis-m3 tries to register the given monitor, so if you run monitis-m3 with '--once' key, be sure you've removed 
   monitor from Monitis.com dashboard before the next run.
   Otherwise ,you will get an error such 'Monitor with that name already exists'!

__Metrics__

      inserts      - number of inserts per second
      query        - number of queries per second
      update       - number of updates per second
      delete       - number of deletes per second
      getmore      - number of get mores (cursor batch) per second
      command      - number of commands per second
      flushes      - number of fsync flushes per second
      mapped       - amount of data mmaped (total data size) megabytes
      visze        - virtual size of process in megabytes
      res          - resident size of process in megabytes
      faults       - number of pages faults per sec (linux only)
      netIn        - network traffic in - bits
      netOut       - network traffic out - bits
      conn         - number of open connections


