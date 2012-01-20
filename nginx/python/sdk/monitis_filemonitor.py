#!/usr/bin/env python
# encoding: utf-8
"""
monitis_filemonitor.py

Created by Jeremiah Shirk on 2011-06-30.
Copyright (c) 2011 Monitis. All rights reserved.
"""

import sys
import getopt
import os
from string import strip
from stat import ST_MODE, ST_SIZE, S_ISDIR, S_ISREG
import csv
from monitisserver import MonitisServer

help_message = '''
This script will send an update for file size monitor

OPTIONS:
   -h      Show this message
   -a      api key
   -s      secret key
   -m      monitor tag (defaults to loadMonitor)
   -i      monitor id (optional)
   -t      timestamp (defaults to utc now)
   -c      config file specifies monitor IDs and file paths
'''

class Usage(Exception):
    def __init__(self, msg):
        self.msg = msg

def fileStats(dirName,depth=1):
    totalSize = 0
    totalCount = 0

    # Ensure that the file or directory exists
    # return 0 for size and count otherwise
    try:
        m = os.stat(dirName)[ST_MODE]
    except OSError:
        return (0,0)

    # count every file encountered in the search, regardless of mode
    totalCount += 1
    if S_ISDIR(m) and depth > 0:
        for f in os.listdir(dirName):
            size,count = fileStats(os.path.join(dirName,f),depth-1)
            totalSize += size
            totalCount +=count
    elif S_ISREG(m):
        totalSize += os.stat(dirName)[ST_SIZE]
    
    return (totalSize,totalCount)
    
def main(argv=None):
    if argv is None:
        argv = sys.argv
    try:
        try:
            opts, args = getopt.getopt(argv[1:], "ha:s:m:i:t:f:c:",["help"])
        except getopt.error, msg:
            raise Usage(msg)
        
        apiKey = None
        apiSecret = None
        monitorTag = "loadMonitor"
        monitorId = None
        action='addResult'
        filePath = None
        config = None
        
        # option processing
        for option, value in opts:
            if option in ("-h", "--help"):
                raise Usage(help_message)
            if option in ("-a"):
                apiKey = value
            if option in ("-s"):
                apiSecret = value
            if option in ("-m"):
                monitorTag = value
            if option in ("-i"):
                monitorId = value
            if option in ("-t"):
                timeStamp = value
            if option in ("-c"):
                config = value

        # cannot continue without the API key and secret
        if ((apiKey is None) or (apiSecret is None)):
            raise Usage("API key and secret must be specified")
        
        # Monitis server will be used for all requests
        monitis = MonitisServer(apiKey, apiSecret)
        
        if config:
            # read id, file path, and search depth from config file in CSV
            reader = csv.reader(open(config,'r'))
            for row in reader:
                (monitorId,path,depth) = map(strip,row)
                # print fileStats(path,int(depth))
                (size,count) = fileStats(path,int(depth))
                result = 'size:{0};count:{1}'.format(size,count)
                print monitis.addResult(monitorId=monitorId,result=result)
                
    except Usage, err:
        print >> sys.stderr, sys.argv[0].split("/")[-1] + ": " + str(err.msg)
        print >> sys.stderr, "\t for help use --help"
        return 2


if __name__ == "__main__":
    # set up python path to get MonitisServer from same dir as running script
    sys.path.append(os.path.abspath(os.path.dirname(sys.argv[0])))
    sys.exit(main())
