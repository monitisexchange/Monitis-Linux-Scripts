#!/usr/bin/env python
# -*- coding: UTF-8 -*-
# vim: set et ts=4:

# Copyright (c) 2011 Citrix System Inc.
# Copyright (c) 2011 Monitis Inc.
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.


# Import of XenServer/XCP RRD data based on example from Citrix community 
# page:
# http://community.citrix.com/display/xs/Getting+the+Last+RRD+Datapoints 

import sys, os, time
import xmlrpclib, urllib
import daemon
import parse_rrd
import monitisserver

global pid_file # path to xen2monitis pid.file
global time_file # path where daemon stores information about last time obtained time
global secret_file # path to the file where information necessary to connect to XenServer and Monitis are store
global xs_url # URL necessary to connect to XenServer



# GETS INFORMATION ABOUT TIME OF LAST UPDATE 
def get_last_time(time_file):
    """get_last_time(time_file) -
        is a function to get the time of last connection to
        XenServer/XCP from a given file.
    """
    
    try :
        last_time = int(open(time_file).read().rstrip('\n'))
    except IOError :
        last_time = int(time.time())
    
    return last_time

# ESTABLISHES CONNECTION TO MONITIS SERVER 
def monitis_connection(key, secret):
    """monitis_connection(key, secret) -
        is a function to establish connection to Monitis server,
        using Monitis API key and secret.
    """
    
    try :
        return monitisserver.MonitisServer(key, secret)
    except Exception, e:
        sys.stderr.write(str(e))
        try :
            sys.remove(pid_file)
        except OSError as e:
            sys.stderr.write(str(e))
        sys.exit(4)

# ESTABLISHES CONNECTION TO XS MASTER POOL
def xs_connection(password, url, user='root'):
    """xs_connection(password, url, user='root') -
        is function to establish connection to XenServer/XCP,
        using password for a given user (default root) and 
        url which points onto pool master.
    """
    
    conn = xmlrpclib.Server(url)
    connection = conn.session.login_with_password(user, password)
    
    if connection['Status'] == 'Success':
        token = connection['Value']
        sys.stderr.write ("\n Connection unique ref: %s\n" %token)
    else :
        for i in connection['ErrorDescription']:
            sys.stderr.write(i)
        try :
            sys.remove(pid_file)
        except OSError as e:
            sys.stderr.write(str(e))
        sys.exit(3)
    return conn, token


class x2mDaemon(daemon.Daemon):
    """x2mDaemon is a class to create a daemon exporting RRD data from XenServer/XCP 
        to Monitis services.
        It based on Daemon class (for more information see daemon.py file.
    """
    def run(self):
        sys.stderr.write('xen2monitis \n') 
        sys.stderr.flush()
        # gets last time
        try :
            time_file
        except NameError:
            time_file = ('/usr/local/lib/xen2monitis/time.file')    

        last_time = get_last_time(time_file)
        
        try :
            secret_file
        except NameError:
            secret_file = ('/usr/local/lib/xen2monitis/secret')
        
        while True:
            # reads secretes from given file
            try :
                secrets = open(secret_file).read().rstrip('/n').split(',')
                secrets = [v.strip() for v in secrets]
            except Exception:
                secrets = []
            try:
                key = secrets[0]
                secret = secrets[1]
            except IndexError:
                sys.stderr.write("Information necessary to connect to Monitis API not define in secret file\n")
                self.delpid()
                sys.exit(2)
            try :
                password = secrets[2]
            except IndexError:
                sys.stderr.write ("Password necessary to connect to XenServer not define in secret file\n")
                self.delpid()
                sys.exit(2)
            
            # establishes connection to Monitis
            mon_obj = monitis_connection(key, secret)
            
            # creates new object for data updates
            rrd_updates = parse_rrd.RRDUpdates()
            
            # dictionary (as in original example) to update default value
            params = {}
            params['cf'] = "AVERAGE"
            params['interval'] = 60
            params['host'] =  'true'
            
            params['start'] = last_time
            
            try :
                xs_url
            except NameError:
                xs_url = 'http://localhost'
            
            # establish connection to XenServer
            xs_conn, xs_token = xs_connection(password, xs_url)
            
            # update data
            rrd_updates.refresh(xs_token, params, xs_url)
            
            # LOOP TO ADD RESULTS FOR HOSTS
            if params['host'] == 'true':
                # LOOP OVER 
                for host_ref in xs_conn.host.get_all(xs_token)['Value']:
                    # LOOP OVER ALL HOSTS
                    for param_name in rrd_updates.get_host_param_list():
                        vm_uuid = rrd_updates.get_host_uuid()
                        monitor_name = "%s - %s (HOST: %s)" % (xs_conn.host.get_hostname(xs_token, host_ref)['Value'], param_name, vm_uuid)
                        sys.stderr.write(monitor_name+'\n')
                        if monitor_name not in mon_obj.dictMonitors().keys() :
                            mon_obj.addMonitor(name=monitor_name, resultParams='1m: 1 Min. Average: :4', tag='XenServer')
                        for row in range(rrd_updates.get_nrows()):                      
                            data = str(rrd_updates.get_host_data(param_name, row))
                            data_time = str(rrd_updates.get_row_time(row)*1000)
                            monitor_id = mon_obj.dictMonitors()[monitor_name][0]
                            mon_obj.addResult(monitorId = monitor_id, result='1m:'+data, checkTime=data_time)
            
            # LOOP TO ADD RESULTS FOR VM
            # LOOP OVER ALL VMs
            for vm_uuid in rrd_updates.get_vm_list():                       
                # LOOP OVER ALL PARAMS FOR GIVEN VM
                for param_name in rrd_updates.get_vm_param_list(vm_uuid):       
                # check if monitor exist
                    vm_ref = xs_conn.VM.get_by_uuid(xs_token,vm_uuid)['Value']
                    monitor_name = "%s - %s (VM: %s)" % (xs_conn.VM.get_name_label(xs_token, vm_ref)['Value'], param_name, vm_uuid)
                    sys.stderr.write(monitor_name+'\n')
                    if monitor_name not in mon_obj.dictMonitors().keys() :
                        mon_obj.addMonitor(name=monitor_name, resultParams='1m: 1 Min. Average: :4', tag='XenServer')
                        # ALL RESULT NEWER THAN LAST CHECK
                    for row in range(rrd_updates.get_nrows()):                      
                        data = str(rrd_updates.get_vm_data(vm_uuid, param_name, row))
                        data_time = str(rrd_updates.get_row_time(row)*1000)
                        monitor_id = mon_obj.dictMonitors()[monitor_name][0]
                        mon_obj.addResult(monitorId = monitor_id, result='1m:'+data, checkTime=data_time) #what is check time - I think it what I expect it is.
           
            # update time of operation
            try :
                open(time_file,'w').write("%d" % time.time())
            except IOError as e:
               sys.stderr.write("PROBLEM WITH TIME FILE\n %s" % e)
            #END OF LOOP           



# MAIN PART
if __name__ == '__main__':

    try :    
        pid_file
    except NameError:
        pid_file = '/var/run/xen2monitis.pid'
    
    # start daemon
    daemon = x2mDaemon(pid_file)
    
    if len(sys.argv) == 2:
        if sys.argv[1] == 'start':
            
            daemon.start()
        
        elif sys.argv[1] == 'stop':
            daemon.stop()
        
        elif sys.argv[1] == 'restart':
            daemon.stop()
            daemon.start()
        else : 
            print ("Unknown command")
    else :
        print ("Please call daemon_test.py with one of following options (start|stop|restart)")

