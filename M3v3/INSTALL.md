## M3 Instllation HOWTO

### M3 packages

In order to have a complete installation, M3 is comprised of 2 main packages:
MonitisMonitorManager package is comprised of 3 main components:
 1. MonitisMonitorManager Perl Module - M3 core infrastructure
 2. M3 executable - /usr/local/bin/monitis-m3
 3. M3 init.d service - /etc/init.d/m3

M3 depends on the Monitis API Perl module

### CPAN Installation

Installing via CPAN is generic and should work on most GNU/Linux systems.

There isn''t much of a difference comparing to other perl modules:

 # cpan install MonitisMonitorManager

This would install the 2 relevant Perl modules, you should still however get

the init.d wrapper package (monitis-m3).

### RHEL/CentOS 6.x or any other recent RPM based distribution

M3 uses a handful of differnt perl modules, you can either install them

via CPAN, or add the <a href="http://wiki.centos.org/AdditionalResources/Repositories/RPMForge">RPMForge</a> and <a href="http://fedoraproject.org/wiki/EPEL">EPEL</a> YUM repositories.

These 2 repositories provide RPM versions of the required perl modules.

Provided in the links below are links to RPMs of the 2 packages:
 * <a href="TODOTODO">perl-Monitis</a>
 * <a href="TODOTODO">perl-MonitisMonitorManager</a>

The following should take care of you:

 # cd /tmp

 # wget -c TODO.rpm TODO.rpm

 # yum localinstall TODO.rpm TODO.rpm

### Debian 6.x

Provided in the links below are links to DEBs of the 2 packages:
 * <a href="TODOTODO">libmonitis-perl</a>
 * <a href="TODOTODO">libmonitismonitormanager-perl</a>

The following should take care of you:

 # cd /tmp

 # wget -c TODO.deb TODO.deb

 # gdebi TODO.deb TODO.deb

### Standalone invocation

/usr/local/bin/monitis-m3 is the main executable in the distribution.

Its configuration resides at /etc/m3.d/M3Templates.pl.

Please edit /etc/m3.d/M3Templates.pl and add your API and secret key.

Once this is done, monitis-m3 can be run:

 # monitis-m3 --dry-run --once /usr/share/doc/perl-MonitisMonitorManager-3.4/eg/etc_file_monitor.xml

monitis-m3 takes a few parameters, to see them all, run:

 # monitis-m3 --help

### Running as /etc/init.d service

The packaged version of M3 provides now an init.d service (/etc/init.d/m3).

Tested on Debian 6.x and RHEL/CentOS 6.x.

M3 service would use the configuration at /etc/m3.d/config.xml and

/etc/m3.d/M3Templates.pl.

M3 log file would reside in /var/log/m3.log.

Please edit /etc/m3.d/M3Templates.pl and add your API and secret key.

To start M3, run:
 
 # /etc/init.d/m3 start

To stop M3, run:

 # /etc/init.d/m3 stop

And to restart M3, run:

 # /etc/init.d/m3 restart
