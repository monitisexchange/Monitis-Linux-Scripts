#!/usr/bin/env python
# encoding: utf-8
"""
monitis_create_monitor.py

Created by Jeremiah Shirk on 2011-06-14.
Copyright (c) 2011 Monitis. All rights reserved.
"""

import sys
import getopt
import os
from monitisserver import MonitisServer


help_message = '''
This script will send an update for system load to a monitor

OPTIONS:
   -h                   Show this message
   -a <key>             api key
   -s <key>             secret key
   -m <tag>             monitor tag
   -n <name>            monitor name
   -r <resultParams>    result parameters
   -i <id>              monitor id (only for delete)
   -l                   list existing monitors
   -d                   delete the monitor identified by <id> or <tag>
'''


class Usage(Exception):
    def __init__(self, msg):
        self.msg = msg

def main(argv=None):
    if argv is None:
        argv = sys.argv
    try:
        try:
            opts, args = getopt.getopt(argv[1:], "hdla:s:m:i:r:n:", ["help"])
        except getopt.error, msg:
            raise Usage(msg)

        try:
            apiKey = os.environ['MONITIS_APIKEY']
        except:
            apiKey = None
        try:
            apiSecret = os.environ['MONITIS_SECRET']
        except:
            apiSecret = None
        monitorTag = None
        monitorName = None
        monitorId = None
        resultParams = None
        action='addMonitor' # default to add, unless we see a -d opt

        # option processing
        for option, value in opts:
            if option in ("-h", "--help"):
                raise Usage(help_message)
            if option in ("-a"):
                apiKey = value
            if option in ("-l"):
                action = 'listMonitors'
            if option in ("-s"):
                apiSecret = value
            if option in ("-m"):
                monitorTag = value
            if option in ("-n"):
                monitorName = value            
            if option in ("-r"):
                resultParams = value
            if option in ("-i"):
                monitorId = value
            if option in ("-d"):
                action = 'deleteMonitor'
        
        # cannot continue without the API key and secret
        if ((apiKey is None) or (apiSecret is None)):
            raise Usage("API key and secret must be specified")

        # Monitis server will be used for all requests
        monitis = MonitisServer(apiKey, apiSecret)
        
        if action is 'addMonitor':
            if monitorTag is None or monitorTag is '':
                raise Usage('monitor tag (-m) is required')
            elif resultParams is None or resultParams is '':
                    raise Usage('result params (-r) is required')
            elif monitorName is None or monitorName is '':
                    raise Usage('monitor name (-n) is required')
            else:
                print monitis.addMonitor(tag=monitorTag,
                                         name=monitorName,
                                         resultParams=resultParams)
        elif action is 'deleteMonitor':
            if monitorId is None or monitorId is '':
                # try to get id from tag
                if monitorTag is None or monitorTag is '':
                    raise Usage('A monitor tag or ID is required')
                else:
                    monitorId = monitis.requestMonitorId(monitorTag) 
            else:
                print monitis.deleteMonitor(monitorId=monitorId)
        
        elif action is 'listMonitors':
            for monitor in monitis.listMonitors():
                print "\t".join(monitor)
    except Usage, err:
        print >> sys.stderr, sys.argv[0].split("/")[-1] + ": " + str(err.msg)
        print >> sys.stderr, "\t for help use --help"
        return 2


if __name__ == "__main__":
    # set up python path to get MonitisServer from same dir as running script
    sys.path.append(os.path.abspath(os.path.dirname(sys.argv[0])))
    sys.exit(main())
