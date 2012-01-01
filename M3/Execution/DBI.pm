package Execution::DBI;
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
	my ($self, $monitor_xml_path, $db_query, $results) = @_;

	# OK, lets extract all the goodies from the XML:
	# db_driver, db_host, db_name, db_username and db_password
	my ($db_driver, $db_host, $db_name, $db_username, $db_password, $output);

	# lets go!!
	# db_driver
	if (!defined($monitor_xml_path->{db_driver}[0])) {
		croak "'db_driver' undefined";
	} else {
		$db_driver = $monitor_xml_path->{db_driver}[0];
	}

	# db_host
	if (!defined($monitor_xml_path->{db_host}[0])) {
		croak "'db_host' undefined";
	} else {
		$db_host = $monitor_xml_path->{db_host}[0];
	}

	# db_name
	if (!defined($monitor_xml_path->{db_name}[0])) {
		croak "'db_name' undefined";
	} else {
		$db_name = $monitor_xml_path->{db_name}[0];
	}

	# db_username
	if (!defined($monitor_xml_path->{db_username}[0])) {
		croak "'db_username' undefined";
	} else {
		$db_username = $monitor_xml_path->{db_username}[0];
	}

	# db_password
	my $use_password = 0;
	if (!defined($monitor_xml_path->{db_password}[0])) {
		# we will just not a password for connection
	} else {
		$use_password = 1;
		$db_password = $monitor_xml_path->{db_password}[0];
	}

	my $dsn = "DBI:$db_driver:$db_name:$db_host";
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

	if (defined($monitor_xml_path->{db_statistics}[0]) && $monitor_xml_path->{db_statistics}[0] == 1) {
		# this will be the response time in ms
		${$results}{&SQL_DELAY}=int((clock_gettime() - $time_begin) * 1000);

		# the numeric response code
		${$results}{&SQL_SUCCESS} = $success_code;
	}

	# fetch the last result
	# TODO only fetchs the last result, as assume the user knows what he is
	# doing and the query is well defined
	my $number_of_rows = 0;
	while (my @data = $sth->fetchrow_array()) {
		$output = $data[0];
		$number_of_rows++;
	}

	if ($number_of_rows > 1) {
		carp "Number of rows fetched in query is more than 1, you might want to fix the query.\n";
	}

	# disconnect!
	$dbh->disconnect();

	# return true
	return $output;
}

# we can add extra counters in this function, such as statistics etc.
sub extra_counters_cb {
	my ($self, $monitis_datatypes, $monitor_xml_path) = @_;

	# return value, extra counters for result parameters
	my $result_params = "";

	# do we need any http statistics in the monitor?
	if (defined($monitor_xml_path->{db_statistics}[0]) && $monitor_xml_path->{db_statistics}[0] == 1) {
		# add these counters also when adding a monitor
		$result_params .= SQL_DELAY . ":" . SQL_DELAY . ":ms:" . $monitis_datatypes->{integer} . ";";
		$result_params .= SQL_SUCCESS . ":" . SQL_SUCCESS . ":code:" . $monitis_datatypes->{boolean} . ";";
	}
	return $result_params;
}

1;
