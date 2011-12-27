#!/usr/bin/python

import monitisserver
import monitiscred

mongo_monitors = [{
    'tag': 'mongoBuildInfo',
    'name': 'Mongo Build Info',
    'params': [
        ['version', 'Mongo Version', 'string', '3', 'false'],
        ['gitVersion', 'Git Version No', 'string', '3', 'false'],
        ['sysInfo', 'System Info', 'string', '3', 'false'],
        ['bits', 'Bits', 'bits', '2', 'false'],
        ['debug', 'Debug', 'string', '1', 'false'],
        ['maxBsonObjectSize', 'Max BSON Object Size', 'string', '1', 'false']
    ]
},{
    'tag': 'mongoListDatabases',
    'name': 'Mongo Databases',
    'params': [
        ['databases', 'Databases', 'string', '3', 'false'],
        ['totalSize', 'Total Size', 'string', '3', 'false']
    ]
},{
    'tag': 'mongoServerStatus',
    'name': 'Mongo Server Status',
    'params': [
        ['host', 'Host', 'string', '3', 'false'],
        ['version', 'Version', 'string', '3', 'false'],
        ['uptime', 'Uptime', 's', '2', 'false'],
        ['uptimeEstimate', 'Uptime Estimate', 's', '2', 'false'],
    ]
},{
    'tag': 'mongoMemory',
    'name': 'Mongo Memory',
    'params': [
        ['membits', 'Memory Bits', 'b', '2', 'false'],
        ['memresident', 'Resident Memory', 'MB', '2', 'false'],
        ['memvirtual', 'Virtual Memory', 'MB', '2', 'false'],
        ['memsupported', 'Memory Supported', 'no', '2', 'false'],
        ['memmapped', 'Memory Mapped', 'no', '2', 'false'],
    ]
},{
    'tag': 'mongoConnections',
    'name': 'Mongo Connections',
    'params': [
        ['connectionscurrent', 'Current Connections', 'no', '2', 'false'],
        ['connectionsavailable', 'Available Connections', 'no', '2', 'false'],
    ]
},{
    'tag': 'mongoOpCounters',
    'name': 'Mongo Op Counters',
    'params': [
        ['opcountersinsert', 'Insert Ops', 'no', '2', 'false'],
        ['opcountersquery', 'Query Ops', 'no', '2', 'false'],
        ['opcountersupdate', 'Update Ops', 'no', '2', 'false'],
        ['opcountersdelete', 'Delete Ops', 'no', '2', 'false'],
        ['opcountersgetmore', 'Get More Ops', 'no', '2', 'false'],
        ['opcounterscommand', 'Command Ops', 'no', '2', 'false'],
    ]
},{
    'tag': 'mongoCursors',
    'name': 'Mongo Cursors',
    'params': [
        ['cursorstotalOpen', 'Total Open Cursors', 'no', '2', 'false'],
        ['cursorsclientCursors_size', 'Client Cursors Size', 'no', '2', 'false'],
        ['cursorstimedOut', 'Cursors Timed Out', 'no', '2', 'false'],
    ]
},{
    'tag': 'mongoNetwork',
    'name': 'Mongo Network',
    'params': [
        ['networkbytesIn', 'Network (In)', 'B', '2', 'false'],
        ['networkbytesOut', 'Network (Out)', 'B', '2', 'false'],
        ['networknumRequests', 'Network (requests)', 'no', '2', 'false'],
    ]
},{
    'tag': 'mongoBackgroundFlushes',
    'name': 'Mongo Background Flushes',
    'params': [        
        ['backgroundFlushingflushes', 'Flushes', 'no', '2', 'false'],
        ['backgroundFlushingtotal_ms', 'Flush Time', 'ms', '2', 'false'],
        ['backgroundFlushingaverage_ms', 'Flush Avg Time', 'ms', '2', 'false'],
    ]
}]

def create_params(params):
    new_list = []
    for item in params:
        new_list.append(':'.join(item))
    return ';'.join(new_list)


if __name__ == '__main__':
    monitis = monitisserver.MonitisServer(monitiscred.KEY, monitiscred.SECRET)
    for monitor in mongo_monitors:
        name = monitor['name']
        tag = monitor['tag']
        params = create_params(monitor['params'])
        print '%s: Creating custom monitor.' % tag
        try:
            print tag + ': ' + monitis.addMonitor(name=name, tag=tag, resultParams=params)
        except:
            print '%s: Did not create, may already exist.' % tag
            pass
