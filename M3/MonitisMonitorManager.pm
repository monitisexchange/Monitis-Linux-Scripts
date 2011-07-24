package MonitisMonitorManager;

use strict;
# don't use strict "refs" as we are going to call templated functions
# that depend on variable names...
no strict "refs";
use XML::Simple;
use Data::Dumper;
use Monitis;
use Carp;

# use the same constant as in the Perl-SDK
use constant DEBUG => $ENV{MONITIS_DEBUG} || 0;

our $VERSION = '0.1';

my %monitis_datatypes = ( 'boolean', 1, 'integer', 2, 'string', 3, 'float', 4 );

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
	my $exec_template = $monitor_xml_path->{exectemplate}[0];

	carp "Running '$exec_template' for '$monitor_name'" if DEBUG;

	my %results = ();
	# running with qx{} as it should run also on windows
	my $exec_output = qx{ $exec_template} || croak "Failed running '$exec_template': $!";
	# TODO will spliting with '\n' work on windows?? - it should...
	foreach my $output_line ( split ('\n', $exec_output) ) {
		# look for each metric on each line
		foreach my $metric_name (keys %{$monitor_xml_path->{metric}} ) {
			my $metric_regex = $monitor_xml_path->{metric}->{$metric_name}->{regex}[0];
			my $metric_type = $monitor_xml_path->{metric}->{$metric_name}->{type}[0];
			if ($output_line =~ m/$metric_regex/) {
				chomp $output_line;
				my $data = $1;
				if ($metric_type eq "boolean") {
					# if it's a boolean, use a positive value instead of
					# the extracted value
					$data = 1;
				} else {
					# if it's not a boolean type, use the extracted data
					my $data = $1;
				}
				carp "Matched '$metric_regex'=>'$data' in '$output_line'";
				# yield a warning here if it's already in the hash
				if (defined($results{$metric_name})) {
					carp "Metric '$metric_name' with regex '$metric_regex' was already parsed!!";
					carp "You should fix your script output ('$exec_template') to have '$metric_regex' only once in the output";
				}
				# push into hash, we'll format it later...
				$results{$metric_name} = $data;
			} elsif ($metric_type eq "boolean") {
				# if the data type is a boolean, and we didn't find the result
				# we were looking for, then it's a 0
				carp "Matched '$metric_regex'=>'0' in '$output_line'";
				$results{$metric_name} = 0;
			}
		}
	}
	my $formatted_results = format_results(\%results);

	# update the data
	return $self->update_data_for_monitor($agent_name, $monitor_name, $formatted_results);
}

# update data for a monitor, calling Monitis API
sub update_data_for_monitor {
	my ($self, $agent_name, $monitor_name, $results) = @_;

	# sanity check of results...
	if ($results eq "") {
		croak "Result set is empty! did it parse well?"; 
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

	if ($self->dry_run()) {
		print "OK\n";
		carp "This is a dry run, data for monitor '$monitor_name' was not really updated.";
	} else {
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
		# TODO TODO Interface here might change
		$self->invoke_monitor($agent_name, $monitor_name);
	}
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
		$formatted_results .= $key . ":" . $results{$key} . ";";
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

