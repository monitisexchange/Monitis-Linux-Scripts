package Execution::RemoteCommand;
use strict;
use MonitisMonitorManager::M3PluginCommon;
require Carp;
require Time::HiRes qw(clock_gettime);
require Net::Telnet;
require Net::SSH::Perl;
require Encode;

sub new {
	my ($class, $name) = @_;
	return undef;
}

# this function identifies the token should be used when parsing
sub name {
	return "remote_command";
}

# returns 0 if configuration is OK
# and populates the given %plugin_parameters hashref
sub get_config {
	my ($self, $plugin_xml_base, $plugin_parameters) = @_;
	
	${$plugin_parameters}{command} =
		MonitisMonitorManager::M3PluginCommon::get_mandatory_parameter($self, $plugin_xml_base, "command");
	${$plugin_parameters}{protocol} =
		MonitisMonitorManager::M3PluginCommon::get_mandatory_parameter($self, $plugin_xml_base, "protocol");
	${$plugin_parameters}{hostname} =
		MonitisMonitorManager::M3PluginCommon::get_mandatory_parameter($self, $plugin_xml_base, "hostname");
	${$plugin_parameters}{username} =
		MonitisMonitorManager::M3PluginCommon::get_mandatory_parameter($self, $plugin_xml_base, "username");
	${$plugin_parameters}{password} =
		MonitisMonitorManager::M3PluginCommon::get_mandatory_parameter($self, $plugin_xml_base, "password");
	${$plugin_parameters}{port} =
		MonitisMonitorManager::M3PluginCommon::get_optional_parameter($self, $plugin_xml_base, "port");
}

# execute a DBI (SQL) query and return the last row fetched
sub execute {
	my ($self, $plugin_xml_base, $results) = @_;

	# OK, lets extract all the goodies from the XML:
	# protocol, hostname, port, username, password
	my %plugin_parameters = ();
	$self->get_config($plugin_xml_base, \%plugin_parameters);

	# use shortcuts for parameters
	my $command = $plugin_parameters{command};
	my $protocol = $plugin_parameters{protocol};
	my $hostname = $plugin_parameters{hostname};
	my $username = $plugin_parameters{username};
	my $password = $plugin_parameters{password};
	my $port = $plugin_parameters{port};

	# change encoding to iso-8859-1
	Encode::from_to($command, 'utf8', 'iso-8859-1');
	Encode::from_to($username, 'utf8', 'iso-8859-1');
	Encode::from_to($password, 'utf8', 'iso-8859-1');

	my $output = "";
	if ($protocol eq "telnet") {
		# configure arguements
		my @telnet_args;
		defined($port) and push @telnet_args, Port => $port;

		eval {
			# connect to remote hostname
			my $telnet_connection = new Net::Telnet(Timeout => 10, @telnet_args);
			$telnet_connection->open($hostname);
			$telnet_connection->login($username, $password);
			$output = join "\n", $telnet_connection->cmd($command);
			$telnet_connection->close();
		}
	} elsif ($protocol eq "ssh") {
		# configure arguements
		my @ssh_args;
		defined($port) and push @ssh_args, Port => $port;
		defined($ENV{MONITIS_DEBUG}) and push @ssh_args, debug => 1;

		eval {
			# login and run command
			my $ssh_connection = Net::SSH::Perl->new($hostname, @ssh_args);
			$ssh_connection->login($username, $password);
			my($ssh_output, $stderr, $exit) = $ssh_connection->cmd($command);
			$output = $ssh_output;
		}
	}

	# return output
	return $output;
}

# we can add extra counters in this function, such as statistics etc.
sub extra_counters_cb {
	return "";
}

1;
