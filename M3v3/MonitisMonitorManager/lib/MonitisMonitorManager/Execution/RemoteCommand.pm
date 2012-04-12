package Execution::RemoteCommand;
use strict;
use MonitisMonitorManager::M3PluginCommon;
use Carp;
use Data::Dumper;
use Time::HiRes qw(clock_gettime);
use XML::Simple;
use Net::Telnet;
use Net::SSH::Perl;
use Encode;

sub new {
	my ($class, $name) = @_;
	return undef;
}

# this function identifies the token should be used when parsing
sub name {
	return "remote_command";
}

# execute a DBI (SQL) query and return the last row fetched
sub execute {
	my ($self, $plugin_xml_base, $results) = @_;

	# OK, lets extract all the goodies from the XML:
	# protocol, hostname, port, username, password
	my $remote_command = M3PluginCommon::get_mandatory_parameter($self, $plugin_xml_base, "command");
	my $protocol = M3PluginCommon::get_mandatory_parameter($self, $plugin_xml_base, "protocol");
	my $hostname = M3PluginCommon::get_mandatory_parameter($self, $plugin_xml_base, "hostname");
	my $username = M3PluginCommon::get_mandatory_parameter($self, $plugin_xml_base, "username");
	my $password = M3PluginCommon::get_mandatory_parameter($self, $plugin_xml_base, "password");
	my $port = M3PluginCommon::get_optional_parameter($self, $plugin_xml_base, "port");

	# change encoding to iso-8859-1
	Encode::from_to($remote_command, 'utf8', 'iso-8859-1');
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
			$output = join "\n", $telnet_connection->cmd($remote_command);
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
			my($ssh_output, $stderr, $exit) = $ssh_connection->cmd($remote_command);
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
