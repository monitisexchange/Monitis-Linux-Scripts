#!/usr/bin/python

import monitiscred
import os, subprocess

try:
    import json
except:
    import simplejson

import monitisserver, monitiscred

HOSTNAME = 'localhost'
PORT = '28017'

BASE_URL = 'http://%s:%s' % (HOSTNAME, PORT)

mongo_monitors = [{
    'tag': 'mongoBuildInfo',
    'url': '%s/buildInfo?json=1' % BASE_URL,
},{
    'tag': 'mongoListDatabases', 
    'url': '%s/listDatabases?json=1' % BASE_URL,
},{
    'tag': 'mongoServerStatus',
    'url': '%s/serverStatus?json=1' % BASE_URL,
},{
    'tag': 'mongoMemory',
    'url': '%s/serverStatus?json=1' % BASE_URL,
},{
    'tag': 'mongoConnections',
    'url': '%s/serverStatus?json=1' % BASE_URL,
},{
    'tag': 'mongoOpCounters',
    'url': '%s/serverStatus?json=1' % BASE_URL,
},{
    'tag': 'mongoCursors',
    'url': '%s/serverStatus?json=1' % BASE_URL,
},{
    'tag': 'mongoNetwork',
    'url': '%s/serverStatus?json=1' % BASE_URL,
},{
    'tag': 'mongoBackgroundFlushes',
    'url': '%s/serverStatus?json=1' % BASE_URL,
}]

if __name__ == '__main__':
    monitis = monitisserver.MonitisServer(monitiscred.KEY, monitiscred.SECRET)
    
    for monitor in mongo_monitors:
        process = subprocess.Popen(['curl', monitor['url']], stdout=subprocess.PIPE)
        data = json.loads(process.communicate()[0])

        result = ''	
        for item in data:
            if type(data[item]) == dict:
                for sub_item in data[item]:
                    value = str(data[item][sub_item]).replace(':', '-').replace(';', '-')
                    name = item + sub_item
                    result += '%s:%s;' % (name, value)
            else:
                value = str(data[item]).replace(':','-').replace(';','-')
                result += '%s:%s;' % (item, value)
        tag = monitor['tag']
	print result
        print tag + ': ' + monitis.addResult(monitorTag=tag, result=result)

