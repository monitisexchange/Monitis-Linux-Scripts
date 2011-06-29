#!/usr/bin/perl -w

use strict;
use DBI;
use Data::Dumper;
use Shell;

# returns the monitis api executable
sub get_monitis_api_executable {
	if ( ! defined ($CFG::CFG{'monitis_api'}{'executable'}) ) {
		print STDERR "monitis_api => executable is undefined.\n";
		exit(1);
	}
	return $CFG::CFG{'monitis_api'}{'executable'};
}

# adds a monitor to monitis
sub monitis_add_monitor {
	my ($monitor_name, $monitor_tag, $result_params) = @_;

	my $monitis_api_executable = &get_monitis_api_executable();
	# call monitis API
	print system("$monitis_api_executable monitis_add_custom_monitor \"$monitor_name\" \"$monitor_tag\" \"$result_params\"");
}

# updates custom monitor data in monitis
sub monnitis_update_data {
	my ($monitor_name, $results) = @_;

	my $monitis_api_executable = &get_monitis_api_executable();
	# call monitis API
	system("$monitis_api_executable monitis_update_custom_monitor_data \"$monitor_name\" \"$results\"");
}

# read the configuration from the file
sub read_config {
	my $config_file = $_[0];
	{
		# source the configuration in CFG namespace
		package CFG;
		my $rc = do($config_file);

		# Check for errors
		if ($@) {
			$::err = "ERROR: Failure compiling '$config_file' - $@";
		} elsif (! defined($rc)) {
			$::err = "ERROR: Failure reading '$config_file' - $!";
		} elsif (! $rc) {
			$::err = "ERROR: Failure processing '$config_file'";
		}
	}
}

# runs a single query and return the result
sub run_query {
	my ($db_driver, $db_host, $db_name, $db_username, $db_password, $db_query, $retval) = @_;
	my $dsn = "DBI:$db_driver:$db_name:$db_host";
	print "DB: '$db_username\@$dsn', Query: '$db_query'\n";

	# connect to DB and run the query
	my $dbh = DBI->connect("$dsn", "$db_username", "$db_password")
		|| print STDERR "Could not connect to database '$db_username\@$dsn': $DBI::errstr" && return 0;

	my $sth = $dbh->prepare($db_query)
		|| print STDERR "Could not prepare query '$db_query': $DBI::errstr" && return 0;

	# execute query and fetch result
	$sth->execute()
		|| print STDERR "Could not execute statement '$db_query': $DBI::errstr" && return 0;

	# fetch the last result
	# TODO only fetchs the last result, as assume the user knows what he is
	# doing and the query is well defined
	my $number_of_rows = 0;
	while (my @data = $sth->fetchrow_array()) {
		$$retval = $data[0];
		$number_of_rows++;
	}

	if ($number_of_rows > 1) {
		print STDERR "Number of rows fetched in query is more than 1, you might want to fix the query.\n";
	}

	# disconnect!
	$dbh->disconnect();

	# return true
	return 1;
}

# run queries and load data to Monitis
sub update_data {
	# pass '1' to activate dry_run mode
	my ($dry_run) = @_;

	# iterate on all queries and run them
	while ( my ($monitor_name, $monitor_data) = each %{$CFG::CFG{'monitors'}} ) {
		my $results = "";
		while ( my ($counter_name, $counter_data) = each %{$$monitor_data{'counters'}} ) {
			#source monitis_api.sh && monitis_update_custom_monitor_data RRD_localhost_munin_memory 'free:305594368;active:879394816'
			my $retval = 0;
			# $retval will be passed by reference and will hold the return value
			# TODO add DB port?
			if ( &run_query( $$counter_data{'db_driver'}, $$counter_data{'db_host'},
				$$counter_data{'db_name'}, $$counter_data{'db_username'},
				$$counter_data{'db_password'}, $$counter_data{'db_query'},
				\$retval ) ) {
				# add it to our results
				$results .= "$counter_name:$retval;";
			}
			else {
				# failure - return 0
				print STDERR "Failure at query '$$counter_data{'db_query'}', will use a retval of 0\n";
				$retval = 0;
			}

			# if it's a dry run, just show the results
			if ( $dry_run ) {
				print "Result for '$$counter_data{'db_query'} on '$$counter_data{'db_name'}\@$$counter_data{'db_host'} => $retval\n";
			}
			print STDERR "-------------\n";
		
	
		}
		# remove last ';' from results
		$results =~ s/;$//;

		# invoke monitis API
		if ( ! $dry_run ) {
			&monnitis_update_data($monitor_name, $results);
		}
	}
}

# add all monitors configured in configuration file
sub add_monitors {
	# iterate on all queries and run them
	while ( my ($monitor_tag, $monitor_data) = each %{$CFG::CFG{'monitors'}} ) {
		# we'll use this to format the result parameters
		my $result_params = "";
		while ( my ($counter_name, $counter_data) = each %{$$monitor_data{'counters'}} ) {
			#source monitis_api.sh && monitis_add_custom_monitor memory RRD_localhost_munin_memory 'free:free:Bytes:2;active:active:Bytes:2'
			# TODO always using an integer (2) here
			if ( ! defined($$counter_data{'name'}) ) {
				print STDERR "'name' is undefined for '$counter_name'\n";
				return 1;
			}
			if ( ! defined($$counter_data{'UOM'}) ) {
				print STDERR "'UOM' is undefined for '$counter_name'\n";
				return 1;
			}
			$result_params .= "$counter_name:$$counter_data{'name'}:$$counter_data{'UOM'}:2;";
		}
		# remove last ';' from result params
		$result_params =~ s/;$//;

		# invoke monitis API
		# it's possible to have a monitor name
		my $monitor_name = $monitor_tag;
		if ( defined $$monitor_data{'name'} ) {
			$monitor_tag = $monitor_tag;
		}
		&monitis_add_monitor($monitor_name, $monitor_tag, $result_params);
	}
}

# main
sub main {
	# Get our configuration information
	if (my $err = read_config('monitis_dbi_config.pl')) {
		print(STDERR $err, "\n");
		exit(1);
	}

	# run functions as they come on the command line
	my $args = join(" ", @ARGV);
	eval($args);
}

&main();

