#!/usr/bin/env python

import base64
import os
import re
import simplejson as json
import socket
import sys
import time
import traceback
import urllib

DEBUG = False

if sys.version_info[0] == 2:  # Python version 2.x
    import httplib

    def b64(s):
        return base64.b64encode(s)
else:   # Python version 3.x
    import http.client as httplib

    def b64(s):
        return base64.b64encode(s.encode('utf-8')).decode('utf-8')


def getFromFile(file_name, searchRegExp, default):
    try:
        f = open(os.path.join(os.getcwd(), file_name), 'r')
        lines = f.readlines()
        f.close()
        # searchRegExp = '^.*USER='
        for line in lines:
            # print str(line) + ' length = '+str(len(line))
            if re.match(searchRegExp, line) is not None:
                return re.sub(searchRegExp, '', line).strip().replace('"', '')
    except:
        pass
    return default


# import monitor_constants as constants

rmqHost = getFromFile('monitor_constant.sh', '^declare.*HOST=', '127.0.0.1')
rmqPort = getFromFile('monitor_constant.sh', '^declare.*PORT=', 15672)
rmqPath = '/api/'
# rmqName = 'admin'
# rmqPswd = 'Access4Rabbit'
rmqName = getFromFile('monitor_constant.sh', '^declare.*USER=', 'guest')
rmqPswd = getFromFile('monitor_constant.sh', '^declare.*PSWD=', 'guest')
NORM_STATE = getFromFile('monitor_constant.sh', '^declare.*NORM_STATE=', 'OK')
IDLE_STATE = getFromFile('monitor_constant.sh', '^declare.*IDLE_STATE=', 'IDLE')
FAIL_STATE = getFromFile('monitor_constant.sh', '^declare.*FAIL_STATE=', 'FAIL')
DURATION = float(getFromFile('monitor_constant.sh', '^declare.*DURATION=', 1)) * 60.0


# print str(rmqHost)+':'+str(rmqPort)+str(rmqPath)+ ' ('+str(rmqName)+'/'+str(rmqPswd)+')'

# Access to the RabbitMQ Management HTTP API,
# execute command and keep the result in the "result" variable
#
# @param CMD {STRING} - command that should be executed
# @return error code
#
def access_rabbitmq(command):
    ret = None
    err = 0
    auth = (rmqName + ":" + rmqPswd)
    headers = {"Authorization": "Basic " + b64(auth)}
    conn = httplib.HTTPConnection(rmqHost, rmqPort)
    try:
        conn.request('GET', rmqPath + command, headers=headers)
        resp = conn.getresponse()
        content = resp.read()
        conn.close()
        ret = content
        err = resp.status
    except socket.error as e:
        ret = 'Could not connect: ' + str(e)
        err = 403
    return (err, ret)


#  Format a timestamp into the form 'x day hh:mm:ss'
#  @param TIMESTAMP {NUMBER} the timestamp in sec
def formatTimestamp(time):
    sec = time % 60
    mins = (time / 60) % 60
    hr = (time / 3600) % 24
    da = time / 86400
    s = "%02u.%02u.%02u" % (hr, mins, sec)
    if da > 0:
        s = str(da) + '-' + str(s)
    return s


def addAdditionalData(jdata, res_array):
    if isinstance(jdata, basestring) and isinstance(res_array, list):
        details = {'details': jdata}
        details = urllib.quote(json.dumps(details), '{}')
        res_array.append(details)


def convert(inp):
    if isinstance(inp, dict):
        return dict([(convert(key), convert(value)) for key, value in inp.iteritems()])
    elif isinstance(inp, list):
        return [convert(element) for element in inp]
    elif isinstance(inp, unicode):
        return inp.encode('utf-8')
    else:
        return inp


def getJSONFromFile(fname):
    jdata = {}
    if fname:
        path = os.path.join(os.getcwd(), fname)
        if os.path.isfile(path):
            f = open(path, 'r')
        else:
            f = open(path, 'w+')
        try:
            jdata = json.load(f)
        except Exception as e:
            pass
        f.close()
    return jdata


def putJsonIntoFile(fname, jdata):
    if fname and isinstance(jdata, dict):
        path = os.path.join(os.getcwd(), fname)
        f = open(path, 'w+')
        jdata['time'] = int(time.time())
        json.dump(jdata, f)
        f.close()


def replaceInFile(fname, new_line):
    ret = None
    if fname and new_line:
        path = os.path.join(os.getcwd(), fname)
        try:
            f = open(path, 'r+')
        except IOError:
            f = open(path, 'w+')
        line = f.readline()
        f.close()
        f = open(path, 'w+')
        ret = line if len(line) > 0 else []
        f.write(str(new_line))
        f.close()
    return ret


ad_res = []

# # get queue info
# access_rabbitmq "queues"
# print('*** queues ***')
queues_count = 0
name = []
state = []
consumers = []
memories = []
msg_ready = []
msg_unack = []
msg_total = []
rate_in = []
rate_get = []
rate_ack = []
try:
    (err, result) = access_rabbitmq('queues')
    if result is not None:
        if err >= 400:
            raise Exception(result)
        queues = json.loads(result)
        queues_count = len(queues)
        if queues_count > 0:
            prev_stats = getJSONFromFile('stats')
            cur_stats = {}
            duration = int(time.time()) - prev_stats.get('time', int(time.time()) - DURATION)
            if DEBUG:
                print 'cur_stats = ' + str(cur_stats)
                print 'prev_stats = ' + str(prev_stats)
                print 'duration = ' + str(duration)

            for i in range(queues_count):
                queue = queues[i]
                queue_name = convert('/' + queue['name']).rsplit('/', 1)[1]
                name.append(queue_name)
                state.append(convert(queue['state']))
                consumers.append(int(queue['consumers']))
                memories.append('%.2f' % (float(queue['memory']) / 1000.0))
                msg_ready.append(queue['messages_ready'])
                msg_unack.append(queue['messages_unacknowledged'])
                msg_total.append(queue['messages'])

                if DEBUG:
                    print 'queue_name = ' + str(queue_name)

                message_stats = queue['message_stats'] if 'message_stats' in queue else {}
                if len(message_stats) > 0:
                    cur_stat = [message_stats['publish'] if 'publish' in message_stats else 0,
                                message_stats['deliver_get'] if 'deliver_get' in message_stats else 0,
                                message_stats['ack'] if 'ack' in message_stats else 0]

                    if DEBUG:
                        print 'cur_stat = ' + str(cur_stat)

                    prev_stat = prev_stats.get(queue_name, cur_stat)

                    if DEBUG:
                        print 'prev_stat = ' + str(prev_stat)

                    rate_in.append('%.2f' % (float(cur_stat[0] - prev_stat[0]) / duration))
                    rate_get.append('%.2f' % (float(cur_stat[1] - prev_stat[1]) / duration))
                    rate_ack.append('%.2f' % (float(cur_stat[2] - prev_stat[2]) / duration))

                    prev_stats[queue_name] = cur_stat

                    if DEBUG:
                        v = message_stats['publish_details'] if 'publish_details' in message_stats else {}
                        rate_in.append('%.2f' % float(v['rate'] if 'rate' in v else 0.0))
                        v = message_stats['deliver_get_details'] if 'deliver_get_details' in message_stats else {}
                        rate_get.append('%.2f' % float(v['rate'] if 'rate' in v else 0.0))
                        v = message_stats['ack_details'] if 'ack_details' in message_stats else {}
                        rate_ack.append('%.2f' % float(v['rate'] if 'rate' in v else 0.0))

                    if DEBUG:
                        print 'rate_in = ' + str(rate_in) + \
                              ' rate_get = ' + str(rate_get) + \
                              ' rate_ack = ' + str(rate_ack)
                else:
                    rate_in.append(0.0)
                    rate_get.append(0.0)
                    rate_ack.append(0.0)
                    prev_stats[queue_name] = [0, 0, 0]

            putJsonIntoFile('stats', prev_stats)

            if DEBUG:
                print 'put into file = ' + str(prev_stats)
        else:
            raise Exception("No any queues are created yet")
except Exception as e:
    traceback.print_exc()
    addAdditionalData(str(e), ad_res)
    status = FAIL_STATE
    param = 'name:?;state:' + str(status) + ';additionalResults:' + str(ad_res).replace("'", "")
    if DEBUG:
        print param
    exit()

param = ('name:' + str(name) + ';state:' + str(state) + ';consumers:' + str(consumers) + ';memory:' + str(
    memories) + ';msg_ready:' + str(msg_ready) + ';msg_unack:' + str(msg_unack) + ';msg_total:' + str(
    msg_total) + ';rate_in:' + str(rate_in) + ';rate_get:' + str(rate_get) + ';rate_ack:' + str(rate_ack)
         ).replace("'", "").replace(' ', '')

print param
