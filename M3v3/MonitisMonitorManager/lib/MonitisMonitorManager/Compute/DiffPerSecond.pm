package MonitisMonitorManager::Compute::DiffPerSecond;
use strict;
use Carp;
my %diff_hash = ();

sub new {
	my ($class, $name) = @_;
	return undef;
}

# this function identifies the token should be used when parsing
sub name {
	return "diffpersec";
}

# perform a diff per X seconds computation on the values provided
# X is represented in $code
sub compute {
	my ($self, $agent_name, $monitor_name, $monitor_xml_path, $code, $results) = @_;
	# if this is the first time, there will be no keys to actually report...
	# so we'll have to remove them
	my @keys_to_remove;
	foreach my $metric_name (keys %{$results}) {
		# retrieve the new data that arrived from the parsing plugin
		my $new_data = ${$results}{$metric_name};
		# ok, lets calculate the diff from last time...
		if ( !defined(&retrieve_value($agent_name, $monitor_name, $metric_name)) ) {
			# this is the first execution, no diff can be done!!
			# mark key for removal
			push @keys_to_remove, $metric_name;
		} else {
			my $diff_data = calculate_diff($agent_name, $monitor_name, $metric_name, $new_data, $code);
			# push into hash
			${$results}{$metric_name} = $diff_data;
		}

		# store the new value
		store_value($agent_name, $monitor_name, $metric_name, $new_data);
	}

	# remove keys
	foreach my $key_to_remove (@keys_to_remove) {
		delete ${$results}{$key_to_remove};
	}
}

sub store_value {
	my ($agent_name, $monitor_name, $metric_name, $data) = @_;
	$diff_hash{$agent_name . "_" . $monitor_name . "_" . $metric_name} = { "data" => $data, "timestamp" => int(time()) };
}

sub retrieve_value {
	my ($agent_name, $monitor_name, $metric_name) = @_;
	return $diff_hash{$agent_name . "_" . $monitor_name . "_" . $metric_name};
}

sub calculate_diff {
	my ($agent_name, $monitor_name, $metric_name, $new_data, $seconds) = @_;
	my $old_data = &retrieve_value($agent_name, $monitor_name, $metric_name)->{"data"};
	my $old_timestamp = &retrieve_value($agent_name, $monitor_name, $metric_name)->{"timestamp"};
	my $new_timestamp = int(time());

	my $diff_data = (int($new_data - $old_data)) / (($new_timestamp - $old_timestamp) / $seconds);

	carp "Evalutaing diff for '$metric_name' = '($new_data - $old_data) / ($new_timestamp - $old_timestamp)' == '$diff_data'";

	return $diff_data;
}

1;
