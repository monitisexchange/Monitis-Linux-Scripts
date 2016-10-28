#!/usr/bin/env python
# -*- coding: UTF-8 -*-
# vim: et ts=4 : 
#
# This code has been prepared by Sander Marechal
# For more information please visit 
# http://www.jejik.com/articles/2007/02/a_simple_unix_linux_daemon_in_python/
# 
# some cosmetic changes has been applied by Wawrzek Niewodniczanski.
#
# It is covered by Attribution-ShareAlike 3.0 Unported (CC BY-SA 3.0)
# http://creativecommons.org/licenses/by-sa/3.0/
#
# You are free:
#    to Share — to copy, distribute and transmit the work
#    to Remix — to adapt the work
#    to make commercial use of the work
#
#Under the following conditions:
#
#    Attribution — You must attribute the work in the manner specified by 
#     the author or licensor (but not in any way that suggests that they 
#     endorse you or your use of the work).
#
#    Share Alike — If you alter, transform, or build upon this work, 
#     you may distribute the resulting work only under the same or similar 
#     license to this one.

import sys, os, time, atexit
from signal import SIGTERM
 
class Daemon:
    """
    A generic daemon class.
   
    Usage: subclass the Daemon class and override the run() method
    """
    def __init__(self, pidfile, stdin='/dev/null', stdout='/var/log/xen2monitis.log', stderr='/var/log/xen2monitis.log'):
        self.stdin = stdin
        self.stdout = stdout
        self.stderr = stderr
        self.pidfile = pidfile
   
    def daemonize(self):
        """
        do the UNIX double-fork magic, see Stevens' "Advanced
        Programming in the UNIX Environment" for details (ISBN 0201563177)
        http://www.erlenstar.demon.co.uk/unix/faq_2.html#SEC16
        """
        try:
            pid = os.fork()
            if pid > 0:
                # exit first parent
                sys.exit(0)
        except OSError, e:
            sys.stderr.write("fork #1 failed: %d (%s)\n" % (e.errno, e.strerror))
            sys.exit(1)
   
        # decouple from parent environment
        os.chdir("/")
        os.setsid()
        os.umask(0)
   
        # do second fork
        try:
            pid = os.fork()
            if pid > 0:
                # exit from second parent
                sys.exit(0)
        except OSError, e:
            sys.stderr.write("fork #2 failed: %d (%s)\n" % (e.errno, e.strerror))
            sys.exit(1)
   
        # redirect standard file descriptors
        sys.stdout.flush()
        sys.stderr.flush()
        si = file(self.stdin, 'r')
        so = file(self.stdout, 'a+')
        se = file(self.stderr, 'a+', 0)
        os.dup2(si.fileno(), sys.stdin.fileno())
        os.dup2(so.fileno(), sys.stdout.fileno())
        os.dup2(se.fileno(), sys.stderr.fileno())
   
        # write pidfile
        atexit.register(self.delpid)
        pid = str(os.getpid())
        try:
            file(self.pidfile,'w+').write("%s\n" % pid)
        except Exception, e:
            sys.stderr.write("Cannot open pidfile")
            sys.exit(44)

    def delpid(self):
        try:
            os.remove(self.pidfile)
        except OSError as e:
            sys.stderr.write("pid file doesn't exist\n")
            sys.stderr.write(str(e))
 
    def start(self):
        """
        Start the daemon
        """
        # Check for a pidfile to see if the daemon already runs
        try:
            pf = file(self.pidfile,'r')
            pid = int(pf.read().strip())
            pf.close()
        except IOError:
            pid = None
    
        if pid:
            message = "pidfile %s already exist. Daemon already running?\n"
            sys.stderr.write(message % self.pidfile)
            sys.exit(1)
        
        # Start the daemon
        self.daemonize()
        self.run()
 
    def stop(self):
        """
        Stop the daemon
        """
        # Get the pid from the pidfile
        try:
            pf = file(self.pidfile,'r')
            pid = int(pf.read().strip())
            pf.close()
        except IOError:
            pid = None
    
        if not pid:
            message = "pidfile %s does not exist. Daemon not running?\n"
            sys.stderr.write(message % self.pidfile)
            return # not an error in a restart
 
        # Try killing the daemon process       
        try:
            while 1:
                os.kill(pid, SIGTERM)
                time.sleep(0.1)
        except OSError, err:
            err = str(err)
            if err.find("No such process") > 0:
                if os.path.exists(self.pidfile):
                    os.remove(self.pidfile)
            else:
                print str(err)
                sys.exit(1)
 
    def restart(self):
        """
        Restart the daemon
        """
        self.stop()
        self.start()
 
    def run(self):
        """
        You should override this method when you subclass Daemon. It will be called after the process has been
        daemonized by start() or restart().
        """

