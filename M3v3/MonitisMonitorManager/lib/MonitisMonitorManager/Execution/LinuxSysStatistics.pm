package Execution::LinuxSysStatistics;
use strict;
use MonitisMonitorManager::M3PluginCommon;
require Carp;
require Sys::Statistics::Linux;
my $linux_sys_statistics = Sys::Statistics::Linux->new( cpustats => 1,memstats  => 1,diskusage => 1 , loadavg   => 1);

sub new {
	my ($class, $name) = @_;

	return undef;
}

# this function identifies the token should be used when parsing
sub name {
	return "linuxsysstats";
}

# croaks if configuration is not good
# and populates the given %plugin_parameters hashref
sub get_config {
	my ($self, $plugin_xml_base, $plugin_parameters) = @_;
	
	${$plugin_parameters}{value} = MonitisMonitorManager::M3PluginCommon::get_mandatory_parameter($self, $plugin_xml_base);
}

# execute perl code executable and return the output
sub execute {
	my ($self, $plugin_xml_base, $results) = @_;

	# get parameters
	my %plugin_parameters = ();
	$self->get_config($plugin_xml_base, \%plugin_parameters);
	my $value = $plugin_parameters{value};

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
