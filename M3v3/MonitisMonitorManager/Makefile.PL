use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'MonitisMonitorManager',
    VERSION_FROM      => 'lib/MonitisMonitorManager.pm', # finds $VERSION
    PREREQ_PM         => {
		'Carp' >= 0,
		'Data::Dumper' >= 0,
		'Date::Manip' >= 0,
		'DBI' >= 0,
		'File::Basename' >= 0,
		'File::Temp' >= 0,
		'JSON' >= 0,
		'List::Util' >= 0,
		'LWP::UserAgent' >= 0,
		'Monitis' >= 0,
		'Net::SNMP' >= 0,
		'Sys::Statistics::Linux' >= 0,
		'Thread::Queue' >= 0,
		'Thread' >= 0,
		'threads::shared' >= 0,
		'Time::HiRes' >= 0,
		'URI::Escape' >= 0,
		'XML::Simple' >= 0,
		'Net::Telnet' >= 0,
		'Net::SSH::Perl' >= 0,
		'Encode' >= 0,
	}, # e.g., Module::Name => 1.1
	BUILD_REQUIRES		=> {
		'Data::Dumper' >= 0,
		'Date::Manip' >= 0,
		'DBI' >= 0,
		'File::Basename' >= 0,
		'File::Temp' >= 0,
		'JSON' >= 0,
		'List::Util' >= 0,
		'Monitis' >= 0,
		'Net::SNMP' >= 0,
		'Sys::Statistics::Linux' >= 0,
		'Thread::Queue' >= 0,
		'Thread' >= 0,
		'Time::HiRes' >= 0,
		'URI::Escape' >= 0,
		'XML::Simple' >= 0,
		'Net::Telnet' >= 0,
		'Net::SSH::Perl' >= 0,
	},
	EXE_FILES			=>
		[ qw(scripts/monitis-m3) ],
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT  => 'Monitis Monitor Manager (M3)', # retrieve abstract from module
       AUTHOR         => 'Dan Fruehauf <malkodan@gmail.com>') : ()),
);
