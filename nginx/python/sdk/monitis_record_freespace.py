#!/usr/bin/env python
# encoding: utf-8
"""
monitis_record_freespace.py

Created by Jeremiah Shirk on 2011-06-08.
Copyright (c) 2011 Monitis. All rights reserved.
"""

import sys
import getopt
import os
from monitisserver import MonitisServer

help_message = '''
This script will send an update for filesystem free space to a monitor

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
        
        # Do the disk measurement
        d = os.statvfs("/")
        mult = d.f_frsize/1024 # adjust to report size in kb
        r = ((d.f_blocks - d.f_bavail)*mult,d.f_blocks*mult,d.f_bavail*mult)
        print r
        freespaceResult = \
            'free:{d[0]};cap:{d[1]};avail:{d[2]}'.format(d=r)
        print monitis.addResult(monitorTag='spaceMonitor',
                                result=freespaceResult)
    
    except Usage, err:
        print >> sys.stderr, sys.argv[0].split("/")[-1] + ": " + str(err.msg)
        print >> sys.stderr, "\t for help use --help"
        return 2


if __name__ == "__main__":
    # set up python path to get MonitisServer from same dir as running script
    sys.path.append(os.path.abspath(os.path.dirname(sys.argv[0])))
    sys.exit(main())
