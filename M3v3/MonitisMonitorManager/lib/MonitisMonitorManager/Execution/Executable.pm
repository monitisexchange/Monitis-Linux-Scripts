package Execution::Executable;
use strict;
use MonitisMonitorManager::M3PluginCommon;
require Carp;

sub new {
	my ($class, $name) = @_;
	return undef;
}

# this function identifies the token should be used when parsing
sub name {
	return "exectemplate";
}

# returns 0 if configuration is OK
# and populates the given %plugin_parameters hashref
sub get_config {
	my ($self, $plugin_xml_base, $plugin_parameters) = @_;
	
	${$plugin_parameters}{executable} = MonitisMonitorManager::M3PluginCommon::get_mandatory_parameter($self, $plugin_xml_base);
}

# execute an executable and return the output
sub execute {
	my ($self, $plugin_xml_base, $results) = @_;

	# extract executable command
	my %plugin_parameters = ();
	$self->get_config($plugin_xml_base, \%plugin_parameters);
	my $executable = $plugin_parameters{executable};

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
