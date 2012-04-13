package Execution::SNMP;
use strict;
use MonitisMonitorManager::M3PluginCommon;
use Carp;
use Data::Dumper;
use Net::SNMP;

sub new {
	my ($class, $name) = @_;
	return undef;
}

# this function identifies the token should be used when parsing
sub name {
	return "oid";
}

# execute perl code executable and return the output
sub execute {
	my ($self, $plugin_xml_base, $results) = @_;
	my $oid = MonitisMonitorManager::M3PluginCommon::get_mandatory_parameter($self, $plugin_xml_base, name());
	my $snmp_hostname = MonitisMonitorManager::M3PluginCommon::get_optional_parameter($self, $plugin_xml_base, "hostname", "localhost");
	my $snmp_community = MonitisMonitorManager::M3PluginCommon::get_optional_parameter($self, $plugin_xml_base, "community", "public");

	my ($session, $error) = Net::SNMP->session(
		-hostname  => $snmp_hostname,
		-community => $snmp_community,
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
