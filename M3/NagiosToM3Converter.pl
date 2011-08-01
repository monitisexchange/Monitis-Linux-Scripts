#!/usr/bin/perl -w

package NagiosToM3Converter;

use strict;
use Nagios::Config;
use Nagios::Object::Config;
use Data::Dumper;
use Carp;
use XML::Writer;

# use the same constant as in the Monitis Perl-SDK and M3
use constant DEBUG => $ENV{MONITIS_DEBUG} || 0;

our $VERSION = '0.1';

sub new {
	my $class = shift;
	my $self = {@_};
	bless $self, $class;

	Nagios::Object::Config->strict_mode(undef);
	# open configuration file
	$self->{nagios_parser} = Nagios::Object::Config->new();
	$self->{nagios_parser}->parse($self->{nagios_configuration});

	# nagios basedir and plugins dir, for plugin invocation
	$self->{nagios_plugins_dir} = "$self->{nagios_basedir}/plugins";

	# this is the XML::Writer instance
	$self->{xml_output} = "";
	$self->{configuration_xml} = new XML::Writer(
		OUTPUT => \$self->{xml_output}, DATA_INDENT => 2, DATA_MODE => 1);

	return $self;
}

# will parse and generate the XML
sub parse {
	my ($self) = @_;

	# initialize some basic stuff
	$self->{configuration_xml}->xmlDecl();
	$self->{configuration_xml}->startTag("config");
	$self->{configuration_xml}->startTag("apicredentials", "apikey" => "XXX", "secretkey" => "XXX");
	$self->{configuration_xml}->endTag("apicredentials");
	$self->{configuration_xml}->startTag("agent", "name" => "nagios monitor");

	# iterate on service_index
	foreach my $service_name (keys %{$self->{nagios_parser}->{service_index}}) {
		foreach my $service_variables ($self->{nagios_parser}->{service_index}{$service_name}[0]) {
			my $hostgroup_name = $service_variables->{hostgroup_name};
			my $check_command = $service_variables->{check_command};
			$self->configure_check_command($check_command, $hostgroup_name);
		}
	}
	$self->{configuration_xml}->endTag("agent");
	$self->{configuration_xml}->endTag("config");
	$self->{configuration_xml}->end();
}

# return the XML object
sub xml {
	my ($self) = @_;
	return $self->{xml_output};
}

# returns a list of hosts for a given host group
sub get_hosts_in_hostgroup {
	my ($self, $hostgroup_name) = @_;

	# find all hosts in the given hostgroup
	my @retval_hosts = ();
	my @hosts_in_hostgroup = $self->{nagios_parser}->find_objects( $hostgroup_name, "Nagios::HostGroup" );
	foreach my $host (keys %{$hosts_in_hostgroup[0]->{object_config_object}->{host_index}}) {
		push(@retval_hosts, $host);
	}
	return @retval_hosts;
}

# gets a command and returns the exact command and regex as for how it
# should be configured in M3 XML
sub configure_check_command_for_host {
	my ($self, $check_command, $host) = @_;
	carp "Configuring check_command: '$check_command', for host '$host'" if DEBUG;

	# retrieve just the base of the command
	my $base_check_command = $check_command; $base_check_command =~ s/!.*//;

	# call a callback for the relevant command
	my $callback = "_cb_$base_check_command";
	$self->$callback($host, $base_check_command, $check_command);
}

# configured a check_command for all its relevant hosts
sub configure_check_command {
	my ($self, $check_command, $hostgroup_name) = @_;
	carp "Configuring check_command: '$check_command', for hosts in group '$hostgroup_name'" if DEBUG;
	foreach my $host ($self->get_hosts_in_hostgroup($hostgroup_name)) {
		$self->configure_check_command_for_host($check_command, $host);
	}
}

######################################
# callbacks for specific plugin care #
######################################
# handle check_http
sub _cb_check_http {
	my ($self, $host, $base_check_command, $check_command) = @_;

	# obtain the host address
	my $host_address = $self->{nagios_parser}->{host_index}->{$host}[0]->{address};
	if (!defined($host_address)) {
		carp "Check '$base_check_command' will not be configured for host '$host', because its address is undefined" if DEBUG;
		return;
	}

	# monitor declaration
	$self->{configuration_xml}->startTag("monitor", "name" => "nagios $base_check_command");
	$self->{configuration_xml}->startTag("exectemplate");
	$self->{configuration_xml}->characters("$self->{nagios_plugins_dir}/$check_command -H $host_address");
	$self->{configuration_xml}->endTag("exectemplate");

	# the metrics
	# first metric
	$self->{configuration_xml}->startTag("metric", "name" => "HTTP check");
	$self->{configuration_xml}->dataElement("type", "boolean");
	$self->{configuration_xml}->dataElement("uom", "Connectivity");
	$self->{configuration_xml}->dataElement("regex", "^HTTP OK");
	$self->{configuration_xml}->endTag("metric");

	# second metric
	$self->{configuration_xml}->startTag("metric", "name" => "HTTP delay");
	$self->{configuration_xml}->dataElement("type", "float");
	$self->{configuration_xml}->dataElement("uom", "seconds");
	$self->{configuration_xml}->dataElement("regex", "time=([0-9\.]+)s;");
	$self->{configuration_xml}->endTag("metric");

	# end the tag
	$self->{configuration_xml}->endTag("monitor");
}

# handle check_ping
sub _cb_check_ping {
	my ($self, $host, $base_check_command, $check_command) = @_;

	# obtain the host address
	my $host_address = $self->{nagios_parser}->{host_index}->{$host}[0]->{address};
	if (!defined($host_address)) {
		carp "Check '$base_check_command' will not be configured for host '$host', because its address is undefined" if DEBUG;
		return;
	}

	# parse some nagios arguments
	my $nagios_arguments = $check_command;
	$nagios_arguments =~ s/.*!(.*)!(.*)/-w $1 -c $1/g;

	# monitor declaration
	$self->{configuration_xml}->startTag("monitor", "name" => "nagios $base_check_command");
	$self->{configuration_xml}->startTag("exectemplate");
	$self->{configuration_xml}->characters("$self->{nagios_plugins_dir}/$base_check_command $nagios_arguments -H $host_address");
	$self->{configuration_xml}->endTag("exectemplate");

	# the metrics
	# first metric
	$self->{configuration_xml}->startTag("metric", "name" => "PING check");
	$self->{configuration_xml}->dataElement("type", "boolean");
	$self->{configuration_xml}->dataElement("uom", "Connectivity");
	$self->{configuration_xml}->dataElement("regex", "^PING OK");
	$self->{configuration_xml}->endTag("metric");

	# second metric
	$self->{configuration_xml}->startTag("metric", "name" => "PING delay");
	$self->{configuration_xml}->dataElement("type", "float");
	$self->{configuration_xml}->dataElement("uom", "milliseconds");
	$self->{configuration_xml}->dataElement("regex", "rta=([0-9\.]+)ms;");
	$self->{configuration_xml}->endTag("metric");

	# third metric
	$self->{configuration_xml}->startTag("metric", "name" => "PING packet loss");
	$self->{configuration_xml}->dataElement("type", "float");
	$self->{configuration_xml}->dataElement("uom", "percent");
	$self->{configuration_xml}->dataElement("regex", "pl=([0-9\.]+)%;");
	$self->{configuration_xml}->endTag("metric");

	# end the tag
	$self->{configuration_xml}->endTag("monitor");
}

# main
sub main {
	my $nagios_config = shift @ARGV;
	if (!defined($nagios_config)) {
		die "Usage: $0 nagios_configuration_file"
	}

	my $NagiosToM3Converter = NagiosToM3Converter->new(
		nagios_configuration => $nagios_config, nagios_basedir => "/usr/lib/nagios");

	# parse & generate XML
	$NagiosToM3Converter->parse();

	# print generated XML to stdout
	print $NagiosToM3Converter->xml() . "\n";
}

&main()
