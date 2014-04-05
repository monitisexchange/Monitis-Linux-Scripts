#!/usr/bin/env python

import json
import commands
import httplib, base64

#import monitor_constants as constants

rmqHost = '127.0.0.1'
rmqPort = 15672
rmqPath = '/api/'
rmqName = 'admin'
rmqPswd = 'Access4Rabbit'
NORM_STATE="OK"
IDLE_STATE="IDLE"
FAIL_STATE="NOK"
UNAC_STATE="status:FAIL | details + Cannot access to the rabbitmq engine"

#Access to the RabbitMQ Management HTTP API, 
# execute command and keep the result in the "result" variable
#
#@param CMD {STRING} - command that should be executed
#@return error code
#
def access_rabbitmq(command):
    ret = None
    auth = base64.encodestring("%s:%s" % (rmqName, rmqPswd))
    headers = {"Authorization" : "Basic %s" % auth}
    conn = httplib.HTTPConnection(rmqHost, rmqPort)
    conn.request('GET', rmqPath+command, headers=headers)
    resp = conn.getresponse()
    content = resp.read()
    conn.close()
    if resp != None and resp.status == 200:
#        print(content)
        ret = content
    return ret
    
    
#  Format a timestamp into the form 'x day hh:mm:ss'
#  @param TIMESTAMP {NUMBER} the timestamp in sec
def formatTimestamp(time):
    sec=time%60
    mins=(time/60)%60
    hr=(time/3600)%24
    da=time/86400
    s="%02u.%02u.%02u" % (hr, mins, sec)
    if da > 0:
        s=str(da)+'-'+str(s) 
    return s

#def getValue(): 
    
errors=0
MSG = {}
# get nodes info
#print('*** nodes ***')
try:
    result = access_rabbitmq('nodes')
    if result != None:
        nodes = json.loads(result)
        run=nodes[0]['running']
        pid=nodes[0]['os_pid']
        up=nodes[0]['uptime']
        upt=formatTimestamp(up / 1000)
        ofd=nodes[0]['fd_used']
        lfd=nodes[0]['fd_total']
        ofdp='%.2f' % (100.0*ofd/lfd)
        osd=nodes[0]['sockets_used']
        lsd=nodes[0]['sockets_total']
        osdp='%.2f' % (100.0*osd/lsd)
        proc=nodes[0]['proc_used']
        lproc=nodes[0]['proc_total']
        procp='%.2f' % (100.0*proc/lproc)
        #mem=nodes[0].mem_used
        #mem_mb=$(echo "scale=1;($mem/1024/1024)" | bc )
        #lmem=nodes[0].mem_limit
        #lmem_mb=$(echo "scale=1;($lmem/1024/1024)" | bc )
        #memp=$(echo "scale=1;(100.0*$mem/$lmem)" | bc )
        #dfree=nodes[0].disk_free
        #dfree_mb=$(echo "scale=1;($dfree/1024/1024)" | bc )
        #ldfree=nodes[0].disk_free_limit
        #ldfree_mb=$(echo "scale=1;($ldfree/1024/1024)" | bc )
        #dfreep=$(echo "scale=1;(100.0*$ldfree/$dfree)" | bc )
        cm = commands.getoutput('ps -p'+str(pid)+' -o %cpu,%mem  | grep -v % ') 
        rr = cm.strip().replace('  ',' ').split(' ', 2);
        cpu_pr=rr[0]
        mem_pr=rr[1]
#        print('cpu=%s, mem=%s' % (cpu_pr, mem_pr)) 
            
        if float(ofdp) > 90 or float(osdp) > 90:
            MSG[errors]="WARN - Too many open files descriptors"
            errors+=1
          
        if float(procp) > 90:
            MSG[errors]="WARN - Too many Erlang processes used ($proc / $lproc)"
            errors+=1        
          
        if float(mem_pr) > 95:
            MSG[errors]="WARN - Memory usage is critically big"
            errors+=1
           
        if float(cpu_pr) > 95:
            MSG[errors]="WARN - CPU usage is critically big"
            errors+=1         
except Exception as e:
    print(UNAC_STATE+' - '+str(e))

# # get overview info    
# access_rabbitmq "overview"
#print('*** overview ***')
try:
    result = access_rabbitmq('overview')
    if result != None:
        overview = json.loads(result)
#        print(overview)
        message_stats = overview['message_stats'] if overview.has_key('message_stats') else {} 
        v=message_stats['publish_details'] if message_stats.has_key('publish_details') else {} 
        v=v['rate'] if 'rate' in v else '0'
        pub_rate='%.2f' % float(v)
        v=message_stats['deliver_details'] if message_stats.has_key('deliver_details') else {}
        v=v['rate'] if 'rate' in v else '0'
        delivery_rate='%.2f' % float(v)
        v=message_stats['ack_details'] if message_stats.has_key('ack_details') else {}
        v=v['rate'] if 'rate' in v else '0'
        ack_rate='%.2f' % float(v)
        v=message_stats['deliver_no_ack_details'] if message_stats.has_key('deliver_no_ack_details') else {}
        v=v['rate'] if 'rate' in v else '0'
        deliver_no_ack_rate='%.2f' % float(v)
        v=message_stats['deliver_get_details'] if message_stats.has_key('deliver_get_details') else {}
        v=v['rate'] if 'rate' in v else '0'
        deliver_get_rate='%.2f' % float(v)
        
        queue_totals = overview['queue_totals'] if overview.has_key('queue_totals') else {} 
        msg=queue_totals['messages'] if queue_totals.has_key('messages') else '0'
        msg_ready=queue_totals['messages_ready'] if queue_totals.has_key('messages_ready') else '0'
        msg_unack=queue_totals['messages_unacknowledged'] if queue_totals.has_key('messages_unacknowledged') else '0'
#        msg_in_queues=int(msg) + int(msg_ready) + int(msg_unack)
        msg_in_queues=int(msg_ready) + int(msg_unack)
          
        if msg_in_queues > 50:
            MSG[errors]="WARN - some numbers of messages are left in queue"
            errors+=1

except Exception as e:
    print(UNAC_STATE+' - '+str(e))

# # get connections info
# access_rabbitmq "connections"
#print('*** connections ***')
conn=0
r_rate=0
w_rate=0
timeout=0
client=''
try:
    result = access_rabbitmq('connections')
    if result != None:
        connections = json.loads(result)
        conn = len(connections)
        if conn > 0:
            for i in range(conn):
                l=len(connections[i])
                if l > 0: 
                    v=connections[i]['recv_oct_details'] if connections[i].has_key('recv_oct_details') else {}
                    r_rate=(v['rate'] if 'rate' in v else 0) + r_rate
                    v=connections[i]['send_oct_details'] if connections[i].has_key('send_oct_details') else {}
                    w_rate=(v['rate']  if 'rate' in v else 0) + w_rate
                    timeout=(connections[i]['timeout'] if connections[i].has_key('timeout') else 0) + timeout 
                    v=connections[i]['client_properties'] if connections[i].has_key('client_properties') else {}
                    client_=(v['product'] if 'product' in v else '')+'_'+(v['version'] if 'version' in v else '')+' '+(v['platform'] if 'platform' in v else '')
                    if len(client) <= 0:
                        client = client_
                    elif client.find(client_) < 0:
                        client+=';'+client_
        else:
          client="No any client establish connections yet" 
        recv_rate='%.2f' % (r_rate/1024.0)
        sent_rate='%.2f' % (w_rate/1024.0)
         
#        print('r_rate=%d, w_rate=%d, timeout=%d' % (r_rate, w_rate, timeout))
#        print('recv_rate=%s, sent_rate=%s' % (recv_rate, sent_rate))
#        print(client)
except Exception as e:
    print(UNAC_STATE+' - '+str(e))

# # get queue info
# access_rabbitmq "queues"
#print('*** queues ***')
queue_count = 0
queue=''
try:
    result = access_rabbitmq('queues')
    if result != None:
        queues = json.loads(result)
        queue_count = len(queues)
        if queue_count > 0:
            for i in range(queue_count):
                message_stats=queues[i]['message_stats'] if queues[i].has_key('message_stats') else {}
                if len(message_stats) > 0:
                    v=message_stats['publish_details'] if message_stats.has_key('publish_details') else {}
                    r_rate=v['rate'] if 'rate' in v else 0
                    v=message_stats['deliver_get_details'] if message_stats.has_key('deliver_get_details') else {}
                    w_rate=v['rate'] if 'rate' in v else 0
                else:
                    r_rate=0 ; w_rate=0
                queue_="'"+queues[i]['name']+"' ("+ ('%d' % (queues[i]['consumers']))+') pub: '+('%.2f' % (r_rate))+' msg/s; get: '+('%.2f' % (w_rate))+' msg/s'
                if len(queue) <= 0:
                    queue=queue_
                elif queue.find(queue_) < 0:
                    queue+='; '+queue_
        else:
           queue="No any queues are created yet" 
except Exception as e:
    print(UNAC_STATE+' - '+str(e))
#print(queue)

details='details'
if errors > 0:
    details+=' + Problems in rabbitmq ('+pid+') '+FAIL_STATE
    for CNT in range(errors):
        details+=' + '+ MSG[CNT]
    status=FAIL_STATE
elif  (conn <= 0) or (queue_count <= 0):
    details+=' + RabbitMQ ('+pid+') '+IDLE_STATE
    status=IDLE_STATE
else:
    details+=' + RabbitMQ ('+pid+') '+NORM_STATE
    details+=' + '+str(conn)+' connections are established'
    details+=' + '+str(queue_count)+' queues are created'
    status=NORM_STATE

details+=' + clients: '+client
details+=' + queues: '+queue
 
param='status:'+str(status)+';osd:'+str(osdp)+';ofd:'+str(ofdp)+';cpu_usage:'+str(cpu_pr)+';mem_usage:'+str(mem_pr) \
    +';recv_mps:'+str(deliver_get_rate)+';sent_mps:'+str(pub_rate)+';msg_queue:'+str(msg_in_queues) \
    +';timeout:'+str(timeout)+';recv_kbps:'+str(recv_rate)+';sent_kbps:'+str(sent_rate)+';uptime:'+str(upt)
return_value=param+' | '+details
print(return_value)


