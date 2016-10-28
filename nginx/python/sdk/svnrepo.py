#!/usr/bin/env python
# encoding: utf-8
"""
svnrepo.py

Created by Jeremiah Shirk on 2011-08-28.
Copyright (c) 2011 Monitis. All rights reserved.
"""

import sys
import os
import re
from subprocess import PIPE,Popen

class RepoCommand:
    def __init__(self,executable):
        self.executable = executable

    def _cmd(self,*args,**kwargs):
        '''Generalize repository command execution'''
        # build command from executable name
        a = list(args)
        a.insert(0,self.executable)
        if 'stderr' in kwargs:
            del kwargs['stderr']
        if 'stdout' in kwargs:
            del kwargs['stdout']
        p = Popen(a,stdout=PIPE,stderr=PIPE,**kwargs)
        return p.stdout.read()


class SvnRepository:
    '''SVN repository, location can be local files or on a remote server'''
    def __init__(self,location):
        self.location = location
        self.cmd = SvnCommand() # using the local version for refactoring
    
    def log(self, authors=None):
        """Parse and return logs for the repository.
        
        If users is specified, then limit the search to commits by that author
        """
        commits = self.cmd.log(self.location,authors=authors)
        return commits
    
    def authors(self, path=None):
        """Usernames of authors who have comitted to the repository"""
        authors = set()
        for (rev,author,date,lines) in self.cmd.log(self.location):
            authors.add(author)
        return authors
    
    def files(self):
        """Files in the repository"""
        return self.cmd.list_files(self.location)


class SvnCommand(RepoCommand):
    def __init__(self):
        self.executable = 'svn'
        self.log_cache = dict()
    
    def list_files(self, location, include_directories = False):
        """List files at a given location, with status, in a tuple"""
        files = {}
        svnout = self._cmd('list','-R', location).rstrip()
        entries = svnout.split("\n")
        for entry in entries:
            if entry.endswith('/') and include_directories:
                files[entry] = 'D'
            else:
                files[entry] = 'F'
        return files

    def log(self, location, authors=None, cache=True):
        """Log entries for the remote SVN repository at location
        
        By default, cache the logs for future queries of that data
        """
        # simple hash to index the cache dict
        def loghash(location, authors):
            if authors:
                return ','.join([location,','.join(authors)])
            else:
                return location
        
        # check cache first
        if cache:
            hash = loghash(location,authors)
            if self.log_cache.has_key(hash):
                # print "Found cached log data at:", hash
                return self.log_cache[hash]
            else:
                logs = self._log(location,authors)
                self.log_cache[hash] = logs
                return logs
        else:
            return self._log(location,authors)

    def _log(self, location, authors=None):
        """Log entries for the remote SVN repository at location"""
        entries = list()
        svnout = self._cmd('log', location.rstrip())
        # print svnout
        # lines for revisions match '^r.*'
        lines = svnout.split("\n");
        log_re = \
            re.compile('^r([0-9]+)\s+\|\s+(\w+)\s+\|([^|]+)\s+\|\s+([0-9]+)')
        for line in lines:
            match = log_re.search(line)
            if match:
                revision = match.group(1)
                author = match.group(2)
                date = match.group(3)
                lines = match.group(4)
                if (authors is None) or (author in authors):
                    entries.append((revision,author,date,lines))
        return entries