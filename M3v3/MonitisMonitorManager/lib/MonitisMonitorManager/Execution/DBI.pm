package MonitisMonitorManager::Execution::DBI;
use strict;
use MonitisMonitorManager::M3PluginCommon;
use Carp;
require Time::HiRes;
use Time::HiRes qw(clock_gettime);
require DBI;

# constants for HTTP statistics
use constant {
	SQL_DELAY => "delay",
	SQL_SUCCESS => "success",
};

sub new {
	my ($class, $name) = @_;
	return undef;
}

# this function identifies the token should be used when parsing
sub name {
	return "sql";
}

# returns 0 if configuration is OK
# and populates the given %plugin_parameters hashref
sub get_config {
	my ($self, $plugin_xml_base, $plugin_parameters) = @_;
	
	${$plugin_parameters}{query} =
		MonitisMonitorManager::M3PluginCommon::get_mandatory_parameter($self, $plugin_xml_base, "query");
	${$plugin_parameters}{driver} =
		MonitisMonitorManager::M3PluginCommon::get_mandatory_parameter($self, $plugin_xml_base, "driver");
	${$plugin_parameters}{hostname} =
		MonitisMonitorManager::M3PluginCommon::get_optional_parameter($self, $plugin_xml_base, "hostname", "localhost");
	${$plugin_parameters}{name} =
		MonitisMonitorManager::M3PluginCommon::get_mandatory_parameter($self, $plugin_xml_base, "name");
	${$plugin_parameters}{username} =
		MonitisMonitorManager::M3PluginCommon::get_mandatory_parameter($self, $plugin_xml_base, "username");
	${$plugin_parameters}{password} =
		MonitisMonitorManager::M3PluginCommon::get_optional_parameter($self, $plugin_xml_base, "password");
	${$plugin_parameters}{statistics} =
		MonitisMonitorManager::M3PluginCommon::get_optional_parameter($self, $plugin_xml_base, "statistics");
}

# execute a DBI (SQL) query and return the last row fetched
sub execute {
	my ($self, $plugin_xml_base, $results) = @_;
	# OK, lets extract all the goodies from the XML:
	# query, driver, hostname, name, username and password
	my %plugin_parameters = ();
	$self->get_config($plugin_xml_base, \%plugin_parameters);

	my $query = $plugin_parameters{query};
	my $driver = $plugin_parameters{driver};
	my $hostname = $plugin_parameters{hostname};
	my $name = $plugin_parameters{name};
	my $username = $plugin_parameters{username};
	my $password = $plugin_parameters{password};
	my $statistics = $plugin_parameters{statistics};

	# hostname
	if (!defined($hostname)) {
		# we will just not a hostname for connection
		$hostname = "";
	}

	# password, use it or not?
	my $use_password = 0;
	defined($password) and $use_password = 1;

	# for the DSN
	my $dsn .= "DBI:$driver:$name";

	# add hostname if it's defined
	if ($hostname ne "") {
		$dsn .= ":$hostname";
	}
	carp "DB: '$username\@$dsn', Query: '$query'\n";

	# connect to DB and run the query
	my $dbh;
	if ($use_password == 1) {
		$dbh = DBI->connect("$dsn", "$username", "$password")
			|| carp "Could not connect to database '$username\@$dsn': $DBI::errstr" && return "";
	} else {
		$dbh = DBI->connect("$dsn", "$username")
			|| carp "Could not connect to database '$username\@$dsn': $DBI::errstr" && return "";
	}

	my $sth = $dbh->prepare($query)
		|| carp "Could not prepare query '$query': $DBI::errstr" && return "";

	# measure time
	my $time_begin = clock_gettime();
	# we assume success, unless execute() fails
	my $success_code = 1;

	# execute query and fetch result
	if (!$sth->execute()) {
		carp "Could not execute statement '$query': $DBI::errstr";
		$success_code = 0;
	}

	if (1 == $statistics) {
		# this will be the response time in ms
		${$results}{&SQL_DELAY}=int((clock_gettime() - $time_begin) * 1000);

		# the numeric response code
		${$results}{&SQL_SUCCESS} = $success_code;
	}

	# fetch the last result
	# TODO only fetchs the last result, assuming the user knows what he is
	# doing and the query is well defined
	my $number_of_rows = 0;
	my $output;
	while (my @data = $sth->fetchrow_array()) {
		$output = $data[0];
		$number_of_rows++;
	}

	if ($number_of_rows > 1) {
		carp "Number of rows fetched in query is more than 1, you might want to fix the query.\n";
	}

	# disconnect!
	$dbh->disconnect();

	# return output
	return $output;
}

# we can add extra counters in this function, such as statistics etc.
sub extra_counters_cb {
	my ($self, $monitis_datatypes, $plugin_xml_base) = @_;
	# statistics exists?
	my $statistics = MonitisMonitorManager::M3PluginCommon::get_optional_parameter($self, $plugin_xml_base, "statistics", 0);

	# return value, extra counters for result parameters
	my $result_params = "";

	# do we need any http statistics in the monitor?
	if (1 == $statistics) {
		# add these counters also when adding a monitor
		$result_params .= SQL_DELAY . ":" . SQL_DELAY . ":ms:" . $monitis_datatypes->{integer} . ";";
		$result_params .= SQL_SUCCESS . ":" . SQL_SUCCESS . ":code:" . $monitis_datatypes->{boolean} . ";";
	}
	return $result_params;
}

1;
