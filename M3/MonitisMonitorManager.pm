package MonitisMonitorManager;

use strict;
# don't use strict "refs" as we are going to call templated functions
# that depend on variable names...
no strict "refs";
use XML::Simple;
use Data::Dumper;
use Monitis;
use Carp;
use File::Basename;
use URI::Escape;
use Thread qw(async);
use threads::shared;

# use the same constant as in the Perl-SDK
use constant DEBUG => $ENV{MONITIS_DEBUG} || 0;

# constants for HTTP statistics
use constant {
	EXECUTION_PLUGIN_DIR => "Execution",
	PARSING_PLUGIN_DIR => "Parsing",
};

our $VERSION = '0.2';

our %monitis_datatypes = ( 'boolean', 1, 'integer', 2, 'string', 3, 'float', 4 );

# a helper variable to signal threads to quit on time
my $condition_loop_stop :shared = 0;

# prevent multiple threads from accessing the monitis API
my $monitis_api_lock :shared = 0;

sub new {
	my $class = shift;
	my $self = {@_};
	bless $self, $class;

	# initialize a static variable
	$self->{monitis_datatypes} = \%monitis_datatypes;

	# open the given XML file
	open (FILE, $self->{configuration_xml} || croak "Failed to open configuration XML: $!");
	my $templated_xml = "";
	while (<FILE>) { $templated_xml .= $_; }

	# run the macros which would change all the %SOMETHING% to a proper value
	run_macros($templated_xml);

	# load execution plugins
	$self->load_plugins_in_directory("execution_plugins", EXECUTION_PLUGIN_DIR);

	# load parsing plugins
	$self->load_plugins_in_directory("parsing_plugins", PARSING_PLUGIN_DIR);

	my $xml_parser = XML::Simple->new(ForceArray => 1);
    $self->{config_xml} = $xml_parser->XMLin($templated_xml);

	# a shortcut to the agents structure
	$self->{agents} = $self->{config_xml}->{agent};

	# initialize Monitis
	carp "Initializing Monitis API with secret_key='$self->{config_xml}->{apicredentials}[0]->{secretkey} and api_key='$self->{config_xml}->{apicredentials}[0]->{apikey}'" if DEBUG;
	$self->{monitis_api_context} = Monitis->new(
		secret_key => $self->{config_xml}->{apicredentials}[0]->{secretkey},
		api_key => $self->{config_xml}->{apicredentials}[0]->{apikey} );

	return $self;
}

# a simple function to dynamically load all perl packages in a given
# directory
sub load_plugins_in_directory {
	my ($self, $plugin_table_name, $plugin_directory) = @_;
	# initialize a new plugin table
	$self->{$plugin_table_name} = ();

	my $full_plugin_directory = $ENV{"PWD"} . "/" . $plugin_directory;
	# iterate on all plugins in directory and load them
	foreach my $plugin_file (<$full_plugin_directory/*.pm>) {
		my $plugin_name = $plugin_directory . "::" . basename($plugin_file);
		$plugin_name =~ s/\.pm$//g;
		# load the plugin
		eval {
			require "$plugin_file";
			$plugin_name->name();
		};
		if ($@) {
			croak "error: $@";
		} else {
			carp "Loading plugin '" . $plugin_name . "'->'" . $plugin_name->name() . "'" if DEBUG;
			$self->{$plugin_table_name}{$plugin_name->name()} = $plugin_name;
		}
	}
}

# does the user want a dry run?
sub dry_run {
	my ($self) = @_;
	if (defined($self->{dry_run}) and $self->{dry_run} == 1) {
		return 1;
	} else {
		return 0;
	}
}

# print the XML after it was templated
sub templated_xml {
	my ($self) = @_;
	my $xmlout = XML::Simple->new(RootName => 'config');
	return $xmlout->XMLout($self->{config_xml});
}

# returns the monitor id with a given tag
sub get_id_of_monitor {
	my ($self, $monitor_tag) = @_;

	# call Monitis using the api context provided
	my $response = $self->{monitis_api_context}->custom_monitors->get(
		tag => $monitor_tag);
	# return the first id of the monitor returned
	if (defined($response->[0]->{id})) {
		return $response->[0]->{id};
	} else {
		croak "Could not obtain ID for monitor '$monitor_tag'";
	}
}

# add a single monitor
sub add_monitor {
	my ($self, $agent_name, $monitor_name) = @_;

	my $monitor_xml_path = $self->{agents}->{$agent_name}->{monitor}->{$monitor_name};

	# format the monitor_tag with underscores (_) instead of spaces
	my $monitor_tag = get_monitor_tag_from_name($monitor_name);
	my $result_params = "";
	foreach my $metric_name (keys %{$monitor_xml_path->{metric}} ) {
		my $uom = $monitor_xml_path->{metric}->{$metric_name}->{uom}[0];
		my $metric_type = $monitor_xml_path->{metric}->{$metric_name}->{type}[0];
		my $data_type = ${ $self->{monitis_datatypes} }{$metric_type} or croak "Incorrect data type '$metric_type'";
		$result_params .= "$metric_name:$metric_name:$uom:$data_type;";
	}

	# we'll let external execution plugins dictate if they want to expose
	# additional counters (HTTP statistics for instance)
	# find the relevant execution plugin and execute its additional counters
	# function
	foreach my $execution_plugin (keys %{$self->{execution_plugins}} ) {
		if (defined($monitor_xml_path->{$execution_plugin}[0])) {
			# executable, URL, SQL command...
			carp "Calling extra_counters_cb for plugin: '$execution_plugin', monitor_name->'$monitor_name'" if DEBUG;
			$result_params .= $self->{execution_plugins}{$execution_plugin}->extra_counters_cb($self->{monitis_datatypes}, $monitor_xml_path);

			# iteration can be broken as we've found the execution plugin
			last;
		}
	}

	# remove redundant last ';'
	$result_params =~ s/;$//;

	# a simple sanity check
	if ($result_params eq "") {
		croak "ResultParams are empty! check your XML file...";
	}

	carp "Adding monitor '$monitor_name' with metrics '$result_params'" if DEBUG;
	print "Adding monitor '$monitor_name'...";

	# call Monitis using the api context provided
	if ($self->dry_run()) {
		print "OK\n";
		carp "This is a dry run, the monitor '$monitor_name' was not really added.";
	} else {
		my $response = $self->{monitis_api_context}->custom_monitors->add(
			name => $monitor_name, tag => $monitor_tag,
			resultParams => $result_params);
		if ($response->{status} eq 'ok') {
			print "OK\n";
		} else {
			print "FAILED: '$response->{status}'\n";
			carp Dumper($response) if DEBUG;
		}
	}
}

# add all monitors for all agents
sub add_agents {
	my ($self) = @_;

	# iterate on agents and add them one by one
	foreach my $agent_name (keys %{$self->{agents}}) {
		carp "Adding agent '$agent_name'" if DEBUG;
		$self->add_agent_monitors($agent_name);
	}
}

# add one agent
sub add_agent_monitors {
	my ($self, $agent_name) = @_;
	
	# iterate on all monitors and add them
	foreach my $monitor_name (keys %{$self->{agents}->{$agent_name}->{monitor}} ) {
		carp "Adding monitor '$monitor_name' for agent '$agent_name'" if DEBUG;
		$self->add_monitor($agent_name, $monitor_name);
	}
}

# invoke a single monitor
sub invoke_monitor {
	my ($self, $agent_name, $monitor_name) = @_;

	# get the xml path for that monitor
	my $monitor_xml_path = $self->{agents}->{$agent_name}->{monitor}->{$monitor_name};

	my $output = "";
	my $uri = undef;

	# result set hash
	my %results = ();

	# find the relevant execution plugin and execute it
	foreach my $execution_plugin (keys %{$self->{execution_plugins}} ) {
		if (defined($monitor_xml_path->{$execution_plugin}[0])) {
			# it's called a URI since it can be anything, from a command line
			# executable, URL, SQL command...
			$uri = $monitor_xml_path->{$execution_plugin}[0];
			carp "Calling execution plugin: '$execution_plugin', URI->'$uri', monitor_name->'$monitor_name'" if DEBUG;
			$output = $self->{execution_plugins}{$execution_plugin}->execute($monitor_xml_path, $uri, \%results);

			# iteration can be broken as we've found the execution plugin
			last;
		}
	}
	if (!defined($uri)) {
		croak "Could not find proper execution plugin for monitor '$monitor_name'";
	}

	# call all parsing plugins
	# TODO can be optimized to include only the relevant plugins
	foreach my $parsing_plugin (keys %{$self->{parsing_plugins}} ) {
		carp "Calling parsing plugin: '$parsing_plugin'" if DEBUG;
		$self->{parsing_plugins}{$parsing_plugin}->parse($monitor_xml_path, $output, $uri, \%results);
	}

	# format results
	my $formatted_results = format_results(\%results);

	# update the data
	return $self->update_data_for_monitor($agent_name, $monitor_name, $formatted_results);
}

# update data for a monitor, calling Monitis API
sub update_data_for_monitor {
	my ($self, $agent_name, $monitor_name, $results) = @_;
	lock($monitis_api_lock);

	# sanity check of results...
	if ($results eq "") {
		croak "Result set is empty! did it parse well?"; 
	}

	if ($self->dry_run()) {
		print "OK\n";
		carp "This is a dry run, data for monitor '$monitor_name' was not really updated.";
		return;
	}

	# get the monitor id, either from the XML, or by calling the API
	my $monitor_id = 0;
	if (defined ($self->{agents}->{$agent_name}->{monitor}->{$monitor_name}->{id}) ) {
		$monitor_id = $self->{agents}->{$agent_name}->{monitor}->{$monitor_name}->{id};
		carp "Obtained monitor_id '$monitor_id' from XML" if DEBUG;
	} else {
		# we have to obtain the monitor id in order to update results
		# to do this we first need the monitor tag
		# TODO add a warning to tell the user to add the monitor id in the XML
		my $monitor_tag = get_monitor_tag_from_name($monitor_name);
		$monitor_id = $self->get_id_of_monitor($monitor_tag);

		carp "Obtained monitor_id '$monitor_id' from API call" if DEBUG;
	}

	# get the time now (time returns time in seconds, multiply by 1000
	# for miliseconds)
	my $checktime = time * 1000;

	# call Monitis using the api context provided
	carp "Calling API with '$monitor_id' '$checktime' '$results'" if DEBUG;

	print "Updating data for monitor '$monitor_name'...";

	my $response = $self->{monitis_api_context}->custom_monitors->add_results(
		monitorId => $monitor_id, checktime => $checktime,
		results => $results);
	if ($response->{status} eq 'ok') {
		print "OK\n";
	} else {
		print "FAILED: '$response->{status}'\n";
		carp Dumper($response) if DEBUG;
	}
}

# invoke all agents, one by one
sub invoke_agents {
	my ($self) = @_;
	foreach my $agent_name (keys %{$self->{agents}} ) {
		$self->invoke_agent_monitors($agent_name);
	}
}

# invoke all monitors, one by one
sub invoke_agent_monitors {
	my ($self, $agent_name) = @_;
	foreach my $monitor_name (keys %{$self->{agents}->{$agent_name}->{monitor}}) {
		$self->invoke_monitor($agent_name, $monitor_name);
	}
}

# signals threads to stop execution
sub agents_loop_stop {
	carp "Stopping execution...";
	lock($condition_loop_stop);
	$condition_loop_stop = 1;
	cond_broadcast($condition_loop_stop);
}

# invoke all agents in a loop with timers enabled
sub invoke_agents_loop {
	my ($self) = @_;
	# initialize all the agents
	my @threads = ();

	foreach my $agent_name (keys %{$self->{agents}} ) {
		push @threads, threads->create(\&invoke_agent_monitors_loop, $self, $agent_name);
	}
	my $running_threads = @threads;

	# register SIGINT to stop the loop
	local $SIG{'INT'} = \&MonitisMonitorManager::agents_loop_stop;

	do {
		foreach my $thread (@threads) {
			if($thread->is_joinable()) {
				$thread->join();
				carp "Thread '$thread' has quitted." if DEBUG;
				$running_threads--;
			}
		}
		sleep 1;
	} while(threads->list(threads::all) > 0);
}

# invoke all monitors of an agent in a loop, taking care to sleep between
# executions
sub invoke_agent_monitors_loop {
	my ($self, $agent_name) = @_;
	my $agent_interval = $self->{agents}->{$agent_name}->{interval};
	carp "Agent '$agent_name' will be invoked every '$agent_interval' seconds'" if DEBUG;

	# this loop will break when the user will hit ^C (SIGINT)
	do {
		foreach my $monitor_name (keys %{$self->{agents}->{$agent_name}->{monitor}}) {
			$self->invoke_monitor($agent_name, $monitor_name);
		}
		lock($condition_loop_stop);
		cond_timedwait($condition_loop_stop, time() + $agent_interval);
	} while(not $condition_loop_stop);
}

# formats a monitor tag from a name
sub get_monitor_tag_from_name {
	my ($monitor_name) = @_;
	{ $_ = $monitor_name; s/ /_/g; return $_ }
}

# formats the hash of results into a string
sub format_results {
	my (%results) = %{$_[0]};
	my $formatted_results = "";
	foreach my $key (keys %results) {
		$formatted_results .= $key . ":" . uri_escape($results{$key}) . ";";
	}
	# remove redundant last ';'
	$formatted_results =~ s/;$//;
	return $formatted_results;
}

# simply replaces the %SOMETHING% with the relevant
# return of a defined function
sub run_macros {
	$_[0] =~ s/%(\w+)%/replace_template($1)/eg;
}

# macro functions
sub replace_template {
	my ($template) = @_;
	my $callback = "_get_$template";
	return &$callback();
}

1;

