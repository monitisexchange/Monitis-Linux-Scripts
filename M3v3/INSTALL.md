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

There isn't much of a difference comparing to other perl modules:

 # cpan install MonitisMonitorManager

This would install the two relevant Perl modules (Monitis Perl SDK and

MonitisMonitorManager) but without the init.d script.

### RHEL 6.x / CentOS 6.x or any other recent RPM based distribution

M3 uses a handful of differnt perl modules, you can either install them

via CPAN, or add the <a href="http://wiki.centos.org/AdditionalResources/Repositories/RPMForge">RPMForge</a> and <a href="http://fedoraproject.org/wiki/EPEL">EPEL</a> YUM repositories.

These 2 repositories provide RPM versions of the required perl modules.

Provided in the links below are links to RPMs of the 2 packages:
 * <a href="http://dir.monitis.com/m3/CentOS6/perl-Monitis-0.92-8.noarch.rpm">perl-Monitis</a>
 * <a href="http://dir.monitis.com/m3/CentOS6/perl-MonitisMonitorManager-3.10-1.noarch.rpm">perl-MonitisMonitorManager</a>

The following should take care of you:

 # cd /tmp

 # wget -c http://dir.monitis.com/m3/CentOS6/perl-Monitis-0.92-8.noarch.rpm http://dir.monitis.com/m3/CentOS6/perl-MonitisMonitorManager-3.10-1.noarch.rpm

 # yum localinstall perl-Monitis-0.92-8.noarch.rpm perl-MonitisMonitorManager-3.10-1.noarch.rpm

### RHEL 5.x / CentOS 5.x

RHEL 5.x / CentOS 5.x is currently unsupported.

We are working to resolve this issue, please stay tuned.

### Fedora Core 16

Please refer to the RHEL/CentOS installation instructions, but use the

following RPMs:
 * <a href="http://dir.monitis.com/m3/FC16/perl-Monitis-0.92-8.noarch.rpm">perl-Monitis</a>
 * <a href="http://dir.monitis.com/m3/FC16/perl-MonitisMonitorManager-3.10-1.noarch.rpm">perl-MonitisMonitorManager</a>

### Debian 6.x / Ubuntu 11.x

Provided in the links below are links to DEBs of the 2 packages:
 * <a href="http://dir.monitis.com/m3/Debian6/libmonitis-perl_0.92_all.deb">libmonitis-perl</a>
 * <a href="http://dir.monitis.com/m3/Debian6/libmonitismonitormanager-perl_3.10-1_all.deb">libmonitismonitormanager-perl</a>

The following should take care of you:

 # cd /tmp

 # wget -c http://dir.monitis.com/m3/Debian6/libmonitis-perl_0.92_all.deb http://dir.monitis.com/m3/Debian6/libmonitismonitormanager-perl_3.10-1_all.deb

 # gdebi libmonitis-perl_0.92_all.deb && gdebi libmonitismonitormanager-perl_3.10-1_all.deb

Alternatively if you don't have gdebi installed for any reason, just use dpkg:

 # dpkg -i libmonitis-perl_0.92_all.deb libmonitismonitormanager-perl_3.10-1_all.deb

On Debian/Ubuntu for some reason building packages is not done with dependencies.

Run this to fulfill most of them

 # apt-get install libxml-simple-perl libjson-perl libdate-manip-perl libsys-statistics-linux-perl libnet-telnet-perl libnet-ssh-perl libsnmp-perl libnet-snmp-perl libdbi-perl

In addition to that, for some reason Net::SSH::Perl is not packaged by

Debian/Ubuntu, so in order to install it via CPAN, run:

 # cpan -i Net::SSH::Perl

### Standalone invocation

/usr/local/bin/monitis-m3 is the main executable in the distribution.

Its configuration resides at /etc/m3.d/M3Templates.pm.

Please edit /etc/m3.d/M3Templates.pm and add your API and secret key.

Once this is done, monitis-m3 can be run:

 # monitis-m3 --dry-run --once /usr/share/doc/perl-MonitisMonitorManager-3.10/eg/etc_file_monitor.xml

On Debian/Ubuntu the documentation directory differ slightly:

 # monitis-m3 --dry-run --once /usr/share/doc/libmonitismonitormanager-perl/examples/etc_file_monitor.xml

monitis-m3 takes a few parameters, to see them all, run:

 # monitis-m3 --help

### Running as /etc/init.d service

The packaged version of M3 provides now an init.d service (/etc/init.d/m3).

Tested on Debian 6.x and RHEL/CentOS 6.x.

M3 service would use the configuration at /etc/m3.d/config.xml and

/etc/m3.d/M3Templates.pm.

M3 log file would reside in /var/log/m3.log.

Please edit /etc/m3.d/M3Templates.pm and add your API and secret key.

To start M3, run:
 
 # /etc/init.d/m3 start

To stop M3, run:

 # /etc/init.d/m3 stop

And to restart M3, run:

 # /etc/init.d/m3 restart

### Net::SSH::Perl Issue

Net::SSH::Perl seems to be a stubborn module. If you are not intending to use
it and couldn't be bothered to install it, you can just delete it by running:

 # rm -f /usr/share/perl5/MonitisMonitorManager/Execution/RemoteCommand.pm 

