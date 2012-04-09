package Execution::Executable;
use strict;
use MonitisMonitorManager::M3PluginCommon;
use Carp;
use Data::Dumper;

sub new {
	my ($class, $name) = @_;
	return undef;
}

# this function identifies the token should be used when parsing
sub name {
	return "exectemplate";
}

# execute an executable and return the output
sub execute {
	my ($self, $plugin_xml_base, $results) = @_;
	my $executable = M3PluginCommon::get_mandatory_parameter($plugin_xml_base);

	# running with qx{} as it should run also on windows
	my $output = qx{ $executable } || carp "Failed running '$executable': $!" && return "";
	return $output;
}

# we can add extra counters in this function, such as statistics etc.
# for this simple executable - we add none
sub extra_counters_cb {
	return "";
}

1;
