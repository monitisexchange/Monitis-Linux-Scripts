package Execution::SNMP;
use strict;
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
	my ($self, $monitor_xml_path, $oid, $results) = @_;

	# hostname defined?
	my $snmp_hostname = "localhost";
	defined($monitor_xml_path->{snmp_hostname}[0]) and $snmp_hostname = $monitor_xml_path->{snmp_hostname}[0];
	print "HOST: $snmp_hostname\n";

	# community defined?
	my $snmp_community = "public";
	defined($monitor_xml_path->{snmp_community}[0]) and $snmp_community = $monitor_xml_path->{snmp_community}[0];

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
