package Execution::URL;
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
	my ($self, $monitor_xml_path, $url, $results) = @_;

	# initialize LWP
	my $browser = LWP::UserAgent->new;

	# credentials defined?
	if (defined($monitor_xml_path->{user}[0]) and defined($monitor_xml_path->{password}[0])) {
		my $user = $monitor_xml_path->{user}[0];
		my $password = $monitor_xml_path->{password}[0];
		carp "Using authentication '" . $user . "'/'" . $password . "'";
		$browser->credentials($user => $password);
	}

	# invoke it!
	my $response_begin = clock_gettime();
	my $response = $browser->get($url) || croak "Failed fetching '$url': $!";
	$output = $response->content;

	# add HTTP statistics if user wants it
	if (defined($monitor_xml_path->{http_statistics}[0]) && $monitor_xml_path->{http_statistics}[0] == 1) {
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
	my ($self, $monitis_datatypes, $monitor_xml_path) = @_;

	# return value, extra counters for result parameters
	my $result_params = "";

	# do we need any http statistics in the monitor?
	if (defined($monitor_xml_path->{http_statistics}[0]) && $monitor_xml_path->{http_statistics}[0] == 1) {
		# add these counters also when adding a monitor
		$result_params .= HTTP_DELAY . ":" . HTTP_DELAY . ":ms:" . $monitis_datatypes->{integer} . ";";
		$result_params .= HTTP_CODE . ":" . HTTP_CODE . ":code:" . $monitis_datatypes->{integer} . ";";
		$result_params .= HTTP_SIZE . ":" . HTTP_SIZE . ":bytes:" . $monitis_datatypes->{integer} . ";";
	}
	return $result_params;
}

1;
