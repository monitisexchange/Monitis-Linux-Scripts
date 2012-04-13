package Execution::DBI;
use strict;
use MonitisMonitorManager::M3PluginCommon;
use Carp;
use Data::Dumper;
use Time::HiRes qw(clock_gettime);
use XML::Simple;
use DBI;

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

# execute a DBI (SQL) query and return the last row fetched
sub execute {
	my ($self, $plugin_xml_base, $results) = @_;
	# OK, lets extract all the goodies from the XML:
	# db_query, db_driver, db_hostname, db_name, db_username and db_password
	my $db_query = MonitisMonitorManager::M3PluginCommon::get_mandatory_parameter($self, $plugin_xml_base, "query");
	my $db_driver = MonitisMonitorManager::M3PluginCommon::get_mandatory_parameter($self, $plugin_xml_base, "driver");
	my $db_hostname = MonitisMonitorManager::M3PluginCommon::get_mandatory_parameter($self, $plugin_xml_base, "hostname");
	my $db_name = MonitisMonitorManager::M3PluginCommon::get_mandatory_parameter($self, $plugin_xml_base, "name");
	my $db_username = MonitisMonitorManager::M3PluginCommon::get_mandatory_parameter($self, $plugin_xml_base, "username");
	my $db_password = MonitisMonitorManager::M3PluginCommon::get_optional_parameter($self, $plugin_xml_base, "password");
	my $db_statistics = MonitisMonitorManager::M3PluginCommon::get_optional_parameter($self, $plugin_xml_base, "statistics", 0);

	# db_hostname
	if (!defined($db_hostname)) {
		# we will just not a hostname for connection
		$db_hostname = "";
	}

	# db_password, use it or not?
	my $use_password = 0;
	defined($db_password) and $use_password = 1;

	# for the DSN
	my $dsn .= "DBI:$db_driver:$db_name";

	# add db_hostname if it's defined
	if ($db_hostname ne "") {
		$dsn .= ":$db_hostname";
	}
	carp "DB: '$db_username\@$dsn', Query: '$db_query'\n";

	# connect to DB and run the query
	my $dbh;
	if ($use_password == 1) {
		$dbh = DBI->connect("$dsn", "$db_username", "$db_password")
			|| carp "Could not connect to database '$db_username\@$dsn': $DBI::errstr" && return "";
	} else {
		$dbh = DBI->connect("$dsn", "$db_username")
			|| carp "Could not connect to database '$db_username\@$dsn': $DBI::errstr" && return "";
	}

	my $sth = $dbh->prepare($db_query)
		|| carp "Could not prepare query '$db_query': $DBI::errstr" && return "";

	# measure time
	my $time_begin = clock_gettime();
	# we assume success, unless execute() fails
	my $success_code = 1;

	# execute query and fetch result
	if (!$sth->execute()) {
		carp "Could not execute statement '$db_query': $DBI::errstr";
		$success_code = 0;
	}

	if (1 == $db_statistics) {
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
	# db_statistics exists?
	my $db_statistics = M3PluginCommon::get_optional_parameter($plugin_xml_base, "statistics", 0);

	# return value, extra counters for result parameters
	my $result_params = "";

	# do we need any http statistics in the monitor?
	if (1 == $db_statistics) {
		# add these counters also when adding a monitor
		$result_params .= SQL_DELAY . ":" . SQL_DELAY . ":ms:" . $monitis_datatypes->{integer} . ";";
		$result_params .= SQL_SUCCESS . ":" . SQL_SUCCESS . ":code:" . $monitis_datatypes->{boolean} . ";";
	}
	return $result_params;
}

1;
