package MonitisMonitorManager;

use 5.008008;
use strict;
# don't use strict "refs" as we are going to call templated functions
# that depend on variable names
no strict "refs";
use warnings;
use XML::Simple;
use Data::Dumper;
use Monitis;
use Carp;
use File::Basename;
use URI::Escape;
use Thread qw(async);
use Date::Manip;
use threads::shared;
use MonitisMonitorManager::MonitisConnection;
use File::Basename;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use MonitisMonitorManager ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '3.0';

# use the same constant as in the Perl-SDK
use constant DEBUG => $ENV{MONITIS_DEBUG} || 0;

# constants for HTTP statistics
use constant {
	EXECUTION_PLUGIN_DIR => "Execution",
	PARSING_PLUGIN_DIR => "Parsing",
	COMPUTE_PLUGIN_DIR => "Compute",
};

our %monitis_datatypes = ( 'boolean', 1, 'integer', 2, 'string', 3, 'float', 4 );

# a helper variable to signal threads to quit on time
my $condition_loop_stop :shared = 0;

# constructor
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

	# load compute plugins
	$self->load_plugins_in_directory("compute_plugins", COMPUTE_PLUGIN_DIR);

	my $xml_parser = XML::Simple->new(ForceArray => 1);
	$self->{config_xml} = $xml_parser->XMLin($templated_xml);

	# a shortcut to the agents structure
	$self->{agents} = $self->{config_xml}->{agent};

	# initialize MonitisConnection - async class for Monitis interaction
	$self->{monitis_connection} = MonitisMonitorManager::MonitisConnection->new(
		apikey => "$self->{config_xml}->{apicredentials}[0]->{apikey}",
		secretkey => "$self->{config_xml}->{apicredentials}[0]->{secretkey}",
	);

	# automatically add monitors
	$self->add_agents();

	return $self;
}

# destructor
sub DESTROY {
	my $self = shift;
	# call parent dtor (not that there is any, but just to make it clean)
	$self->SUPER::DESTROY if $self->can("SUPER::DESTROY");
	# umn, why would destroy be called multiple times?
	# because we pass $self to every running thread, so shallow copying
	# will occur. only the main thread will have MonitisConnection defined
	# though
	defined($self->{monitis_connection}) and $self->{monitis_connection}->stop();
}

# a simple function to dynamically load all perl packages in a given
# directory
sub load_plugins_in_directory($$$) {
	my ($self, $plugin_table_name, $plugin_directory) = @_;
	# initialize a new plugin table
	$self->{$plugin_table_name} = ();

	# TODO a little ugly - but this is how we're going to discover where M3
	# was installed...
	my $m3_perl_module_directory = dirname($INC{"MonitisMonitorManager.pm"}) . "/MonitisMonitorManager";
	my $full_plugin_directory = $m3_perl_module_directory . "/" . $plugin_directory;
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
sub dry_run($) {
	my ($self) = @_;
	if (defined($self->{dry_run}) and $self->{dry_run} == 1) {
		return 1;
	} else {
		return 0;
	}
}

# does the user want a mass load?
# mass_load decides how to handle output
# if it's set, we'll handle it line by one, allowing duplicate parameters
sub mass_load($) {
	my ($self) = @_;
	if (defined($self->{mass_load}) and $self->{mass_load} == 1) {
		return 1;
	} else {
		return 0;
	}
}

# print the XML after it was templated
sub templated_xml($) {
	my ($self) = @_;
	my $xmlout = XML::Simple->new(RootName => 'config');
	return $xmlout->XMLout($self->{config_xml});
}

# returns the monitor id with a given tag
sub get_id_of_monitor($$$) {
	my ($self, $monitor_tag, $monitor_name) = @_;

	# call Monitis using the api context provided
	my $response = $self->{monitis_api_context}->custom_monitors->get(
		tag => $monitor_tag);

	# iterate on all of them and compare the name
	my $i = 0;
	while (defined($response->[$i]->{id})) {
		if ($response->[$i]->{name} eq $monitor_name) {
			carp "Monitor tag/name: '$monitor_tag/$monitor_name' -> ID: '$response->[$i]->{id}'" if DEBUG;
			return $response->[$i]->{id};
		}
		$i++;
	}
	croak "Could not obtain ID for monitor '$monitor_tag'";
}

# add a single monitor
sub add_monitor($$$) {
	my ($self, $agent_name, $monitor_name) = @_;

	my $monitor_xml_path = $self->{agents}->{$agent_name}->{monitor}->{$monitor_name};

	# get the monitor tag
	my $monitor_tag = $self->get_monitor_tag($agent_name, $monitor_name);
	my $result_params = "";
	foreach my $metric_name (keys %{$monitor_xml_path->{metric}} ) {
		if ($self->metric_name_not_reserved($metric_name)) {
			my $uom = $monitor_xml_path->{metric}->{$metric_name}->{uom}[0];
			my $metric_type = $monitor_xml_path->{metric}->{$metric_name}->{type}[0];
			my $data_type = ${ $self->{monitis_datatypes} }{$metric_type} or croak "Incorrect data type '$metric_type'";
			$result_params .= "$metric_name:$metric_name:$uom:$data_type;";
		}
	}

	# monitor type (can also be undef)
	my $monitor_type = $self->{agents}->{$agent_name}->{monitor}->{$monitor_name}->{type};

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
		carp "ResultParams are empty for monitor '$monitor_name'... Skipping!";
		return;
	}

	carp "Adding monitor '$monitor_name' with metrics '$result_params'" if DEBUG;

	# call Monitis using the api context provided
	if ($self->dry_run()) {
		carp "This is a dry run, the monitor '$monitor_name' was not really added.";
	} else {
		my @add_monitor_optional_params;
		defined($monitor_type) && push @add_monitor_optional_params, type => $monitor_type;
		$self->{monitis_connection}->add_monitor(
			$monitor_name, $monitor_tag, $result_params, @add_monitor_optional_params);
	}
}

# add all monitors for all agents
sub add_agents($) {
	my ($self) = @_;

	# iterate on agents and add them one by one
	foreach my $agent_name (keys %{$self->{agents}}) {
		carp "Adding agent '$agent_name'" if DEBUG;
		$self->add_agent_monitors($agent_name);
	}
}

# add one agent
sub add_agent_monitors($$) {
	my ($self, $agent_name) = @_;
	
	# iterate on all monitors and add them
	foreach my $monitor_name (keys %{$self->{agents}->{$agent_name}->{monitor}} ) {
		carp "Adding monitor '$monitor_name' for agent '$agent_name'" if DEBUG;
		$self->add_monitor($agent_name, $monitor_name);
	}
}

# invoke a single monitor
sub invoke_monitor($$$) {
	my ($self, $agent_name, $monitor_name) = @_;

	# get the xml path for that monitor
	my $monitor_xml_path = $self->{agents}->{$agent_name}->{monitor}->{$monitor_name};

	my $output = "";
	my $last_uri = undef;

	# result set hash
	my %results = ();

	# find the relevant execution plugin and execute it
	# TODO execution might be out of order in some cases
	foreach my $execution_plugin (keys %{$self->{execution_plugins}} ) {
		if (defined($monitor_xml_path->{$execution_plugin}[0])) {
			foreach my $uri (@{$monitor_xml_path->{$execution_plugin}}) {
				# it's called a URI since it can be anything, from a command line
				# executable, URL, SQL command...
				carp "Calling execution plugin: '$execution_plugin', URI->'$uri', monitor_name->'$monitor_name'" if DEBUG;
				my %returned_results = ();
				$output .= $self->{execution_plugins}{$execution_plugin}->execute($monitor_xml_path, $uri, \%returned_results);
				$output .= "\n";

				# merge the returned results into the main %results hash
				@results{keys %returned_results} = values %returned_results;

				# we will not break execution as we might execute a few plugins
				$last_uri = $uri;
			}
		}
	}
	if (!defined($last_uri)) {
		croak "Could not find proper execution plugin for monitor '$monitor_name'";
	}

	my $retval = 1;
	# if mass load is set, we'll handle the lines one by one
	if ($self->mass_load()) {
		foreach my $line (split /[\r\n]+/, $output) {
			$retval = $self->handle_output_chunk($agent_name, $monitor_xml_path, $monitor_name, $last_uri, \%results, $line);
		}
	} else {
		$retval = $self->handle_output_chunk($agent_name, $monitor_xml_path, $monitor_name, $last_uri, \%results, $output);
	}
}

sub handle_output_chunk($$$$$$$) {
	my ($self, $agent_name, $monitor_xml_path, $monitor_name, $last_uri, $ref_results, $output) = @_;
	my %results = %$ref_results;

	foreach my $metric_name (keys %{$monitor_xml_path->{metric}} ) {
		# call the relevant parsing plugin
		my %returned_results = ();

		# run the parsing plugin one by one
		foreach my $potential_parsing_plugin (keys %{$monitor_xml_path->{metric}->{$metric_name}}) {
			if (defined($self->{parsing_plugins}{$potential_parsing_plugin})) {
				carp "Calling parsing plugin: '$potential_parsing_plugin'" if DEBUG;
				$self->{parsing_plugins}{$potential_parsing_plugin}->parse($metric_name, $monitor_xml_path->{metric}->{$metric_name}, $output, $last_uri, \%returned_results);
			}
		}

		# call the relevant compute plugins
		# TODO computation might be out of order in some cases when chaining
		foreach my $potential_compute_plugin (keys %{$monitor_xml_path->{metric}->{$metric_name}}) {
			if (defined($self->{compute_plugins}{$potential_compute_plugin})) {
				foreach my $code (@{$monitor_xml_path->{metric}->{$metric_name}->{$potential_compute_plugin}}) {
					carp "Calling compute plugin: '$potential_compute_plugin'" if DEBUG;
					my $code = $monitor_xml_path->{metric}->{$metric_name}->{$potential_compute_plugin}[0];
					$self->{compute_plugins}{$potential_compute_plugin}->compute($agent_name, $monitor_name, $monitor_xml_path, $code, \%returned_results);
				}
			}
		}

		# merge the returned results into the main %results hash
		@results{keys %returned_results} = values %returned_results;
	}

	# TODO 'MONITIS_CHECK_TIME' hardcoded
	# if MONITIS_CHECK_TIME is defined, use it as the timestamp for updating data
	my $checktime = 0;
	if (defined($results{MONITIS_CHECK_TIME})) {
		if (int($results{MONITIS_CHECK_TIME}) == $results{MONITIS_CHECK_TIME}) {
			# no need for date manipulation
			$checktime = $results{MONITIS_CHECK_TIME};
		} else {
			my $date = new Date::Manip::Date;
			$date->parse($results{MONITIS_CHECK_TIME});
			# checktime here is seconds, update_data_for_monitor will multiply by
			# 1000 to make it milliseconds
			$checktime = $date->secs_since_1970_GMT();
		}
		# and remove it from the hash
		delete $results{MONITIS_CHECK_TIME};
	}

	# format results
	my $formatted_results = format_results(\%results);

	# update the data
	if ($checktime ne "") {
		# was the checktime specified and parsed?
		return $self->update_data_for_monitor($agent_name, $monitor_name, $formatted_results, $checktime);
	} else {
		return $self->update_data_for_monitor($agent_name, $monitor_name, $formatted_results);
	}
}

# update data for a monitor, calling Monitis API
sub update_data_for_monitor {
	my ($self, $agent_name, $monitor_name, $results, @va_list) = @_;
	# get the time now (time returns time in seconds, multiply by 1000
	# for miliseconds)
	my $checktime = $va_list[0] || time;
	$checktime *= 1000;

	# sanity check of results...
	if ($results eq "") {
		carp "Result set is empty! did it parse well? - Will not update any data!"; 
		return;
	}

	if ($self->dry_run()) {
		carp "OK\n";
		carp "This is a dry run, data for monitor '$monitor_name' was not really updated.";
		return;
	}

	# queue it on MonitisConnection which will handle the rest
	my $monitor_tag = $self->get_monitor_tag($agent_name, $monitor_name);
	$self->{monitis_connection}->queue($agent_name, $monitor_name, $monitor_tag, $checktime, $results);
}

# invoke all agents, one by one
sub invoke_agents($) {
	my ($self) = @_;
	foreach my $agent_name (keys %{$self->{agents}} ) {
		$self->invoke_agent_monitors($agent_name);
	}
}

# invoke all monitors, one by one
sub invoke_agent_monitors($$) {
	my ($self, $agent_name) = @_;
	foreach my $monitor_name (keys %{$self->{agents}->{$agent_name}->{monitor}}) {
		$self->invoke_monitor($agent_name, $monitor_name);
	}
}

# signals threads to stop execution
sub agents_loop_stop() {
	carp "Stopping execution...";
	lock($condition_loop_stop);
	$condition_loop_stop = 1;
	cond_broadcast($condition_loop_stop);
}

# invoke all agents in a loop with timers enabled
sub invoke_agents_loop($) {
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
	} while($running_threads > 0);
}

# invoke all monitors of an agent in a loop, taking care to sleep between
# executions
sub invoke_agent_monitors_loop($$) {
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
sub get_monitor_tag($$$) {
	my ($self, $agent_name, $monitor_name) = @_;
	# if monitor tag is defined, use it!
	if (defined ($self->{agents}->{$agent_name}->{monitor}->{$monitor_name}->{tag}) ) {
		my $monitor_tag = $self->{agents}->{$agent_name}->{monitor}->{$monitor_name}->{tag};
		carp "Obtained monitor tag '$monitor_tag' from XML" if DEBUG;
		return $monitor_tag;
	} else {
		# make a monitor tag from name
		{ $_ = $monitor_name; s/ /_/g; return $_ }
	}
}

# formats the hash of results into a string
sub format_results(%) {
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
sub run_macros() {
	$_[0] =~ s/%(\w+)%/replace_template($1)/eg;
}

# macro functions
sub replace_template($) {
	my ($template) = @_;
	my $callback = "_get_$template";
	return &$callback();
}

sub metric_name_not_reserved($$) {
	my ($self, $metric_name) = @_;
	return $metric_name ne "MONITIS_CHECK_TIME";
}


# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

MonitisMonitorManager - Perl extension for blah blah blah

=head1 SYNOPSIS

  use MonitisMonitorManager;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for MonitisMonitorManager, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Dan Fruehauf, E<lt>malkodan@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Dan Fruehauf

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
