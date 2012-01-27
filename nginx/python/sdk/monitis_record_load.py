#!/usr/bin/env python
# encoding: utf-8
"""
monitis_record_load.py

Created by Jeremiah Shirk on 2011-06-08.
Copyright (c) 2011 Monitis. All rights reserved.
"""

import sys
import getopt
import os
from monitisserver import MonitisServer

help_message = '''
This script will send an update for system load to a monitor

OPTIONS:
   -h      Show this message
   -a      api key
   -s      secret key
   -m      monitor tag (defaults to loadMonitor)
   -i      monitor id (optional)
   -t      timestamp (defaults to utc now)
'''

class Usage(Exception):
    def __init__(self, msg):
        self.msg = msg

def main(argv=None):
    if argv is None:
        argv = sys.argv
    try:
        try:
            opts, args = getopt.getopt(argv[1:], "ha:s:m:i:t:",["help"])
        except getopt.error, msg:
            raise Usage(msg)
        
        apiKey = None
        apiSecret = None
        monitorTag = "loadMonitor"
        monitorId = None
        action='addResult'
        
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

        # cannot continue without the API key and secret
        if ((apiKey is None) or (apiSecret is None)):
            raise Usage("API key and secret must be specified")
        
        # Monitis server will be used for all requests
        monitis = MonitisServer(apiKey, apiSecret)
        
        # Do the load averages check, and the add the result to monitis
        loadAverages = os.getloadavg()
        loadAveragesResult = \
            '1m:{la[0]};5m:{la[1]};15m:{la[2]}'.format(la=loadAverages)
        print monitis.addResult(monitorTag='loadMonitor',
                                result=loadAveragesResult)
    
    except Usage, err:
        print >> sys.stderr, sys.argv[0].split("/")[-1] + ": " + str(err.msg)
        print >> sys.stderr, "\t for help use --help"
        return 2


if __name__ == "__main__":
    # set up python path to get MonitisServer from same dir as running script
    sys.path.append(os.path.abspath(os.path.dirname(sys.argv[0])))
    sys.exit(main())
