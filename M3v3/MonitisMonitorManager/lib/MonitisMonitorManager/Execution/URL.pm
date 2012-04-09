package Execution::URL;
use strict;
use MonitisMonitorManager::M3PluginCommon;
use Carp;
use Data::Dumper;
use LWP::UserAgent;
use Time::HiRes qw(clock_gettime);
use XML::Simple;

# constants for HTTP statistics
use constant {
	HTTP_DELAY => "delay",
	HTTP_CODE => "code",
	HTTP_SIZE => "size",
};

sub new {
	my ($class, $name) = @_;
	return undef;
}

# this function identifies the token should be used when parsing
sub name {
	return "url";
}

# execute an executable and return the output
sub execute {
	my ($self, $plugin_xml_base, $results) = @_;
	my $url = M3PluginCommon::get_mandatory_parameter($plugin_xml_base, name());
	my $username = M3PluginCommon::get_optional_parameter($plugin_xml_base, "username");
	my $password = M3PluginCommon::get_optional_parameter($plugin_xml_base, "password");
	my $http_statistics = M3PluginCommon::get_optional_parameter($plugin_xml_base, "statistics");

	# initialize LWP
	my $browser = LWP::UserAgent->new;

	# credentials defined?
	if (defined($username) and defined($password)) {
		carp "Using authentication '" . $username . "'/'" . $password . "'";
		$browser->credentials($username => $password);
	}

	# invoke it!
	my $response_begin = clock_gettime();
	my $response = $browser->get($url) || croak "Failed fetching '$url': $!";
	my $output = $response->content;

	# add HTTP statistics if user wants it
	if (defined($http_statistics) and $http_statistics == 1) {
		# this will be the response time in ms
		${$results}{&HTTP_DELAY}=int((clock_gettime() - $response_begin) * 1000);

		# the numeric response code
		${$results}{&HTTP_CODE}=$response->code;

		# page size
		${$results}{&HTTP_SIZE}=length($output);
	}

	return $output;
}

# we can add extra counters in this function, such as statistics etc.
sub extra_counters_cb {
	my ($self, $monitis_datatypes, $plugin_xml_base) = @_;
	# db_statistics exists?
	my $http_statistics = M3PluginCommon::get_optional_parameter($plugin_xml_base, "statistics", 0);

	# return value, extra counters for result parameters
	my $result_params = "";

	# do we need any http statistics in the monitor?
	if (1 == $http_statistics) {
		# add these counters also when adding a monitor
		$result_params .= HTTP_DELAY . ":" . HTTP_DELAY . ":ms:" . $monitis_datatypes->{integer} . ";";
		$result_params .= HTTP_CODE . ":" . HTTP_CODE . ":code:" . $monitis_datatypes->{integer} . ";";
		$result_params .= HTTP_SIZE . ":" . HTTP_SIZE . ":bytes:" . $monitis_datatypes->{integer} . ";";
	}
	return $result_params;
}

1;
