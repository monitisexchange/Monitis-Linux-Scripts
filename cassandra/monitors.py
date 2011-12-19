
cassandra_monitors = [{
    'tag': 'cassandraRingInfo',
    'name': 'Cassandra Ring Info',
    'params': [
        ['totalNodes', 'Total Nodes', 'no', '2', 'false'],
        ['runningNodes', 'Running Nodes', 'no', '2', 'false'],
    ]
},{
    'tag': 'cassandraNodeInfo',
    'name': 'Cassandra Node Info',
    'params': [
        ['token', 'Token', 'string', '3', 'false'],
        ['gossipActive', 'Gossip Active', 'string', '3', 'false'],
        ['generationNo', 'Generation No', 'no', '2', 'false'],
        ['uptime', 'Uptime', 's', '2', 'false'],
        ['heapMemoryUsed', 'Heap Memory Used', 'MB', '2', 'false'],
        ['heapMemoryAvailable', 'Heap Memory Available', 'MB','2', 'false'],
        ['dataCenter', 'Data Center', 'string', '3', 'false'],
        ['rack', 'Rack', 'string', '3', 'false'],
        ['exceptions', 'Exceptions', 'no', '2', 'false'] 
    ]
}]

column_family_params = [
    ['ssTableCount', 'SSTable Count', 'no', '2', 'false'],
    ['spaceUsedLive', 'Space Used (live)', 'MB', '2', 'false'],
    ['spaceUsedTotal', 'Space Used (total)', 'MB', '2', 'false'],
    ['numberOfKeys', 'Number of Keys (estimate)', 'no', '2', 'false'],
    ['memtableColumnsCount', 'Memtable Columns Count', 'no', '2', 'false'],
    ['memtableDataSize', 'Memtable Data Size', 'no', '2', 'false'],
    ['memtableSwitchCount', 'Memtable Switch Count', 'no', '2', 'false'],
    ['readCount', 'Read Count', 'no', '2', 'false'],
    ['readLatency', 'Read Latency', 'ms', '2', 'false'],
    ['writeCount', 'Write Count', 'no', '2', 'false'],
    ['writeLatency', 'Write Latency', 'ms', '2', 'false'],
    ['pendingTasks', 'Pending Tasks', 'no', '2', 'false'],
    ['keyCacheCapacity', 'Key Cache Capacity', 'no', '2', 'false'],
    ['keyCacheSize', 'Key Cache Size', 'no', '2', 'false'],
    ['keyCacheHitRate', 'Key Cache Hit Rate', 'no', '2', 'false'],
    ['rowCache', 'Row Cache', 'string', '3', 'false'],
    ['compactedRowMinimumSize', 'Compacted Row Minimum Size', 'no', '2', 'false'],
    ['compactedRowMaximumSize', 'Compacted Row Maximum Size', 'no', '2', 'false'],
    ['compactedRowMeanIze', 'Compacted Row Mean Size', 'no', '2', 'false'] 
]
