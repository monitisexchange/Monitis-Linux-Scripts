#
# Cookbook Name:: monitis
# Recipe:: default
# Author:: 
#
# Copyright 2012, Monitis, Inc
#

if platform?("debian", "ubuntu", "centos", "fedora", "suse", "redhat")

execute "stop_monitis" do
   cwd "#{node[:MONITIS][:INSTALLDIR]}/monitis"
   command "./monitis.sh stop"
   action :run
end

execute "remove_monitis" do
   cwd "/tmp/"
   command "rm -rf #{node[:MONITIS][:INSTALLDIR]}/monitis"
   action :run
end

end

if platform?("windows")

arch = node[:kernel][:machine]

if "#{arch}" == "x86_64"

template "C:/Windows/Temp/uninstall.bat" do
  source "uninstall.bat.erb"
#  mode "0644"
end

path = "%ProgramFiles(x86)%"


else

path = "%ProgramFiles%"

end

bat = "C:/Windows/Temp/uninstall.bat"

execute "uninstall" do
#  cwd "#{path}"
  command "#{bat}"
end

execute "remove_bat" do
  command "rm -r #{bat}"
end

end
