package MonitisMonitorManager::Execution::SNMP;
use strict;
use MonitisMonitorManager::M3PluginCommon;
use Carp;
require Net::SNMP;

sub new {
	my ($class, $name) = @_;
	return undef;
}

# this function identifies the token should be used when parsing
sub name {
	return "oid";
}

# croaks if configuration is bad
# and populates the given %plugin_parameters hashref
sub get_config {
	my ($self, $plugin_xml_base, $plugin_parameters) = @_;
	
	${$plugin_parameters}{oid} =
		MonitisMonitorManager::M3PluginCommon::get_mandatory_parameter($self, $plugin_xml_base, "oid");
	${$plugin_parameters}{hostname} =
		MonitisMonitorManager::M3PluginCommon::get_optional_parameter($self, $plugin_xml_base, "hostname", "localhost");
	${$plugin_parameters}{community} =
		MonitisMonitorManager::M3PluginCommon::get_optional_parameter($self, $plugin_xml_base, "community", "public");
}

# execute perl code executable and return the output
sub execute {
	my ($self, $plugin_xml_base, $results) = @_;

	# get parameters
	my %plugin_parameters = ();
	$self->get_config($plugin_xml_base, \%plugin_parameters);
	my $oid = $plugin_parameters{oid};
	my $hostname = $plugin_parameters{hostname};
	my $community = $plugin_parameters{community};

	my ($session, $error) = Net::SNMP->session(
		-hostname  => $hostname,
		-community => $community,
	);

	if (!defined $session) {
		carp "SNMP Error: ", $error;
		return "";
	}

	my $result = $session->get_request(-varbindlist => [ $oid ],);

	if (!defined $result) {
		carp "SNMP Error: ", $session->error();
		$session->close();
		return "";
	}

	my $output = $result->{$oid};

	$session->close();
	return $output
}

# we can add extra counters in this function, such as statistics etc.
# for this simple executable - we add none
sub extra_counters_cb {
	return "";
}

1;
