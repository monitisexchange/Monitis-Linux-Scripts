package Execution::RemoteCommand;
use strict;
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
	my ($self, $monitor_xml_path, $remote_command, $results) = @_;

	# OK, lets extract all the goodies from the XML:
	# protocol, host, port, username, password
	my ($protocol, $host, $port, $username, $password, $output);

	# lets go!!
	# protocol
	if (!defined($monitor_xml_path->{protocol}[0])) {
		croak "'protocol' undefined";
	} else {
		$protocol = $monitor_xml_path->{protocol}[0];
	}

	# host
	if (!defined($monitor_xml_path->{host}[0])) {
		# we will just not a hostname for connection
		$host = "";
	} else {
		$host = $monitor_xml_path->{host}[0];
	}

	# port
	$port = $monitor_xml_path->{port}[0];

	# username
	if (!defined($monitor_xml_path->{username}[0])) {
		croak "'username' undefined";
	} else {
		$username = $monitor_xml_path->{username}[0];
	}

	# password
	my $use_password = 0;
	if (!defined($monitor_xml_path->{password}[0])) {
		# we will just not a password for connection
	} else {
		$use_password = 1;
		$password = $monitor_xml_path->{password}[0];
	}

	# change encoding to iso-8859-1
	Encode::from_to($remote_command, 'utf8', 'iso-8859-1');
	Encode::from_to($username, 'utf8', 'iso-8859-1');
	Encode::from_to($password, 'utf8', 'iso-8859-1');

	if ($protocol eq "telnet") {
		# configure arguements
		my @telnet_args;
		defined($port) and push @telnet_args, Port => $port;

		# connect to remote host
		my $telnet_connection = new Net::Telnet(Timeout => 10, @telnet_args);
		$telnet_connection->open($host);
		$telnet_connection->login($username, $password);
		$output = join "\n", $telnet_connection->cmd($remote_command);
		$telnet_connection->close();
	} elsif ($protocol eq "ssh") {
		# configure arguements
		my @ssh_args;
		defined($port) and push @ssh_args, Port => $port;
		defined($ENV{MONITIS_DEBUG}) and push @ssh_args, debug => 1;

		# login and run command
		my $ssh_connection = Net::SSH::Perl->new($host, @ssh_args);
		$ssh_connection->login($username, $password);
		my($ssh_output, $stderr, $exit) = $ssh_connection->cmd($remote_command);
		$output = $ssh_output;
	}

	# return output
	return $output;
}

# we can add extra counters in this function, such as statistics etc.
sub extra_counters_cb {
	return "";
}

1;
