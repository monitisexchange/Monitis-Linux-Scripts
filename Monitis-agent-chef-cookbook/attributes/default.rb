#
# Cookbook Name:: monitis
# Attributes:: default
#
# Author:: 
#
# Copyright 2012, Monitis, Inc.


# default attributes for all platforms
default['MONITIS']['INSTALLDIR'] = "/usr/local"
default['MONITIS']['USEREMAIL'] = "youremail@address.com"
default['MONITIS']['AGENTNAME'] = node[:hostname]

default['MONITIS']['TARBALL_32'] = "MonitisLinuxAgent-32bit.tar.gz"
default['MONITIS']['TARBALL_64'] = "MonitisLinuxAgent-64bit.tar.gz"
default['MONITIS']['TARBALL_URL_32'] = "http://www.monitissupport.com/agents/MonitisLinuxAgent-32bit.tar.gz"
default['MONITIS']['TARBALL_URL_64'] = "http://www.monitissupport.com/agents/MonitisLinuxAgent-64bit.tar.gz"

# overrides on a platform-by-platform basis
case platform
when "debian","ubuntu"

default['MONITIS']['LIBSSL'] = "libssl1.0.0"

when "redhat","centos","fedora"
default['MONITIS']['LIBSSL'] = "openssl-devel"

when "suse"

default['MONITIS']['LIBSSL'] = "libopenssl1_0_0"

when "windows"

default['MONITIS']['TARBALL'] = "MonitisWindowsAgent-32-64bit.zip"
default['MONITIS']['TARBALL_URL'] = "http://www.monitissupport.com/agents/MonitisWindowsAgent-32-64bit.zip"

end
