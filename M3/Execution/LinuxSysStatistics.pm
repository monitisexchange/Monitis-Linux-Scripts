package Execution::LinuxSysStatistics;
use strict;
use Carp;
use Data::Dumper;
use Sys::Statistics::Linux;
my $linux_sys_statistics = Sys::Statistics::Linux->new( cpustats => 1,memstats  => 1,diskusage => 1 , loadavg   => 1);

sub new {
	my ($class, $name) = @_;

	return undef;
}

# this function identifies the token should be used when parsing
sub name {
	return "linuxsysstats";
}

# execute perl code executable and return the output
sub execute {
	my ($self, $monitor_xml_path, $value, $results) = @_;
	my $sysinfo  = $linux_sys_statistics->get(1);
	carp "Evaluating: \$sysinfo->$value == " . eval "\$sysinfo->$value";
	my $output = eval "\$sysinfo->$value";
	return $output;
}

# we can add extra counters in this function, such as statistics etc.
# for this simple executable - we add none
sub extra_counters_cb {
	return "";
}

1;
