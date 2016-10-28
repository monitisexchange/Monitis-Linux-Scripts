#!/usr/bin/env python
# encoding: utf-8
"""
svnmon.py

Created by Jeremiah Shirk on 2011-09-28.
Copyright (c) 2011 Monitis. All rights reserved.
"""

import os
import sys
import getopt
from monitisserver import MonitisServer
from svnrepo import SvnRepository

help_message = '''
Send an update of SVN repository metrics to the Monitis server

OPTIONS:
   -h       Show this message
   -a       api key
   -s       secret key
   -m       monitor tag (defaults to svnMonitor)
   -i       monitor id (optional)
   -t       timestamp (defaults to the current time in UTC)
   -u       repository URL
   -q       repository query to monitor
                files   - number of files in version control (Default)
                authors - number of authors who have committed
                commits - total number of commits to the repository
'''

class Usage(Exception):
    def __init__(self, msg):
        self.msg = msg


def main(argv=None):
    if argv is None:
        argv = sys.argv
    try:
        try:
            opts, args = getopt.getopt(argv[1:], "ha:s:m:i:t:q:u:",["help"])
        except getopt.error, msg:
            raise Usage(msg)
        
        # Defaults
        try:
            apiKey = os.environ['MONITIS_APIKEY']
        except:
            apiKey = None
        try:
            apiSecret = os.environ['MONITIS_SECRET']
        except:
            apiSecret = None
        monitorTag = "svnMonitor"
        monitorId = None
        action='addResult'
        queries=list() 
        repoUrl = None
        
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
            if option in ("-q"):
                queries.append(value)
            if option in ("-u"):
                repoUrl = value
        
        # default for queries if none were specified in the args
        if len(queries) == 0:
            queries = ['files']
            
        # cannot continue without the API key and secret
        if ((apiKey is None) or (apiSecret is None)):
            raise Usage("API key and secret must be specified")
        
        # without the repository URL, there is nothing to query
        if (repoUrl is None):
            raise Usage("Repository URL must be specified")
        
        # Monitis server will be used for all requests
        monitis = MonitisServer(apiKey, apiSecret)
        if monitorId is None:
            try:
                monitorId = monitis.requestMonitorId(monitorTag)
            except:
                raise Usage("Couldn't get ID for monitor tag: " + monitorTag)
                
        # query the repository
        repo = SvnRepository(repoUrl)
        results = list()
        for query in queries:
            # files query
            if query == 'files':
                count = len(repo.files())
                results.append('svnfiles:{0}'.format(count))
            # commits
            elif query == 'commits':
                count = len(repo.log())
                results.append('commits:{0}'.format(count))
            elif query == 'authors':
                count = len(repo.authors())
                results.append('authors:{0}'.format(count))
            else:
                print "Unsupported query type:", query
        
        # report the collected value
        all_results = ';'.join(results)
        print "Sending result:", all_results
        print monitis.addResult(monitorId=monitorId, result=all_results)
        
    except Usage, err:
        print >> sys.stderr, sys.argv[0].split("/")[-1] + ": " + str(err.msg)
        print >> sys.stderr, "\t for help use --help"
        return 2


if __name__ == "__main__":
    # set up python path to get MonitisServer from same dir as running script
    sys.path.append(os.path.abspath(os.path.dirname(sys.argv[0])))
    sys.exit(main())
