#!/usr/bin/env python
# encoding: utf-8

"""
nginx_stubstatus.py

Prepare Nginx StubStatus page for Monitis
Use MonitisPythonSDK (by Jeremiah Shrik)
Require Python ElementTree Package

Created by Glenn Y. Chen on 2012-01-01.
Copyright (c) 2012 Monitis. All rights reserved.
"""

import urllib2

class NginxStubStatus:
    def __init__(self, status_url):
        #todo: if the page url is not good, throw exception
        self.status_url = status_url
        self.ACTIVE_CONNECT = ""
        self.ACCEPT = ""
        self.HANDLED_CONNECT = ""
        self.HANDLED_REQ = ""
        self.READ = ""
        self.WRITE = ""
        self.WAIT = ""

    def get_nginx_stats_results_for_monitis(self):
        page = self.fetch_nginx_status_page()
        self.parse_nginx_status_page(page)
        return "ActiveConnect:" + self.ACTIVE_CONNECT \
            + ";Accept:" + self.ACCEPT \
            + ";Handled:" + self.HANDLED_CONNECT \
            + ";Handles:" + self.HANDLED_REQ \
            + ";Read:" + self.READ \
            + ";Write:" + self.WRITE \
            + ";Wait:" + self.WAIT

    def fetch_nginx_status_page(self):
        f = urllib2.urlopen(self.status_url)
        return f.read()

    def parse_nginx_status_page(self, page):
        lines = page.split('\n')
        active_connections = lines[0] 
        requests = lines[2]
        read_write_wait = lines[3]

        self.parse_active_connection(active_connections)
        self.parse_request(requests)
        self.parse_read_write_wait(read_write_wait)

    def parse_active_connection(self, line):
        line = line[line.find(':')+2:]
        line = line.strip()
        self.ACTIVE_CONNECT = line

    def parse_request(self, line):
        requests = line.split(' ')
        self.ACCEPT = requests[1]
        self.HANDLED_CONNECT = requests[2]
        self.HANDLED_REQ = requests[3]

    def parse_read_write_wait(self, line):
        line = line.upper()
        line = line.replace('READING', '')
        line = line.replace('WRITING', '')
        line = line.replace('WAITING', '')
        line = line.replace(':', '')
        stats = line.split(' ')
        self.READ = stats[1]
        self.WRITE = stats[3]
        self.WAIT = stats[5]
        
    def getResultParams(self):
        activeConnections = 'ActiveConnect:ActiveConnect:ActiveConnects:2;'
        accept = 'Accept:Accept:Accepts:2;'
        handled = 'Handled:Handled:Handleds:2;'
        handles = 'Handles:Handles:Handle:2;'
        read = 'Read:Read:Reads:2;'
        write = 'Write:Write:Writes:2;'
        wait = 'Wait:Wait:Waits:2;'
        resultParams = wait + write + read + handles + handled + accept + activeConnections;
        return resultParams  

    #todo: should we include this function?
    '''
    def isDuplicateMonitor(self):
        m =  ms.listMonitors()
        for item in m:
            m_tag = item[1].replace(" ", "+")
            m_name = item[2]
            if m_tag == tag and m_name == name:
                return True

        return False
    '''


if __name__ == "__main__":
    status_url = 'http://localhost/nginx_status'
    nginx = NginxStubStatus(status_url)
    result = nginx.get_nginx_stats_results_for_monitis()

    #add a custom monitor
    from sdk.monitisserver import MonitisServer
    #sandbox
    #apikey = '5HSONGP5QPK8V09KMTUPIGSOA'
    #apiSecret = '6GF9AVJEI6LN2CJ6S32VFGBKL4'

    #real
    apikey = '14NAC40PIMSUEEBQFJOQL18T5U'
    apiSecret = '74H6U7A2DG71JU80QR48FEOPAL'

    ms = MonitisServer(apikey, apiSecret)
    name = 'Nginx Monitor'
    resultParams = nginx.getResultParams()
    tag = 'Nginx+Stub+Status'
    

    #check if the monitor is already added (same name and tag)
    isDuplicateMonitor = False
    m =  ms.listMonitors()
    for item in m:
        m_tag = item[1].replace(" ", "+")
        m_name = item[2]
        if m_tag == tag and m_name == name:
            isDuplicateMonitor = True

    if not isDuplicateMonitor:
        ms.addMonitor(name, resultParams, tag)
    
    import time
    sleep_seconds = 10
    while 1:
        result = nginx.get_nginx_stats_results_for_monitis()
        ms.addResult(monitorId=None, monitorTag=tag,\
                     result=result, checkTime=None)
        print "result added:", result
        time.sleep(sleep_seconds)

    #c charp token add resut post sample
    #apikey=14NAC40PIMSUEEBQFJOQL18T5U&validation=token&authToken=4HPAIJHD32Q52R4Q94J1D0VDCD&version=2&action=addResult&monitorId=2177&timestamp=2012-01-05 22:38:47&checktime=1325821127751&results=ActiveConnect:1;Accept:41;Handled:41;Handles:45;Read:0;Write:1;Wait:0&
