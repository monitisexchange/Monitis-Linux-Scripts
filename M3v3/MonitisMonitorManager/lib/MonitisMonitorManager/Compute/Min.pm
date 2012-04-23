package Compute::Min;
use strict;
require Carp;
require List::Util qw(min);
my %min_hash = ();

sub new {
	my ($class, $name) = @_;
	return undef;
}

# this function identifies the token should be used when parsing
sub name {
	return "min";
}

# takes the minimum value out of X iterations
# X is represented in $code
sub compute {
	my ($self, $agent_name, $monitor_name, $monitor_xml_path, $code, $results) = @_;
	# if this is the first time, there will be no keys to actually report...
	# so we'll have to remove them

	# some sanity testing
	if ( $code <= 0 ) {
		croak "Iteration number X  - <min>X</min> - must be bigger than 0";
	}

	my @keys_to_remove;
	foreach my $metric_name (keys %{$results}) {
		# retrieve the new data that arrived from the parsing plugin
		my $new_data = ${$results}{$metric_name};
		# ok, lets calculate the diff from last time...
		if ( !defined(&retrieve_value($agent_name, $monitor_name, $metric_name)) ) {
			# this is the first execution, no diff can be done!!
			# mark key for removal
			push @keys_to_remove, $metric_name;
			store_value($agent_name, $monitor_name, $metric_name, $new_data, 1);
		} else {
			my $old_data = &retrieve_value($agent_name, $monitor_name, $metric_name)->{"data"};
			my $iteration = &retrieve_value($agent_name, $monitor_name, $metric_name)->{"iteration"};
			$iteration++;
			store_value($agent_name, $monitor_name, $metric_name, min($old_data, $new_data), $iteration);

			# test whether we should give back a value...
			if ( $iteration % $code == 0 ) {
				# ok, time to show a result!
				${$results}{$metric_name} = &retrieve_value($agent_name, $monitor_name, $metric_name)->{"data"};
				# delete the value, a new iteration will start now
				delete_value($agent_name, $monitor_name, $metric_name);
			} else {
				# it's not time to return a min value, wait for next iteration
				push @keys_to_remove, $metric_name;
			}
		}
	}

	# remove keys
	foreach my $key_to_remove (@keys_to_remove) {
		delete ${$results}{$key_to_remove};
	}
}

sub store_value {
	my ($agent_name, $monitor_name, $metric_name, $data, $iteration) = @_;
	$min_hash{$agent_name . "_" . $monitor_name . "_" . $metric_name} = { "data" => $data, "iteration" => $iteration };
}

sub retrieve_value {
	my ($agent_name, $monitor_name, $metric_name) = @_;
	return $min_hash{$agent_name . "_" . $monitor_name . "_" . $metric_name};
}

sub delete_value {
	my ($agent_name, $monitor_name, $metric_name) = @_;
	delete $min_hash{$agent_name . "_" . $monitor_name . "_" . $metric_name};
}

1;
