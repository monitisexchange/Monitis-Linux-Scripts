name		  "Monitis"
maintainer        "Monitis, Inc."
maintainer_email  "info@monitis.com"
license           ""
description       "Installs and configures monitis monitoring agent"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           "1.0.1"
recipe 		  "monitis", "Installs and configures Monitis Agent"

%w{ ubuntu debian redhat centos fedora opensuse }.each do |os|
  supports os
end

