package MonitisMonitorManager::Parsing::Regex;
use MonitisMonitorManager::M3PluginCommon;
use strict;

sub new {
	my ($class, $name) = @_;
	return undef;
}

# this function identifies the token should be used when parsing
sub name {
	return "regex";
}

# matches regexes the user defined
sub parse {
	my ($self, $metric_name, $metric_xml_path, $output, $results) = @_;

	# if metric is boolean, set it as 0, first of all
	# if it will be matched, it'll turn into a 1
	if ($metric_type eq "boolean") {
		if (not defined(${$results}{$metric_name})) {
			${$results}{$metric_name} = 0;
		}
	}

	# this handles the regex matching
	# [\r\n]+ should work also on windows
	foreach my $output_line ( split /[\r\n]+/, $output ) {
		# look for the metric regex on each line
		if (defined($metric_xml_path->{$self->name()}[0])) {
			my $metric_regex = $metric_xml_path->{$self->name()}[0];
			my $metric_type = $metric_xml_path->{type}[0];
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
				MonitisMonitorManager::M3PluginCommon::log_message("debug", "Matched '$metric_regex'=>'$data' in '$output_line'");
				# yield a warning here if it's already in the hash
				# but don't show it if it's a boolean type :)
				if (defined(${$results}{$metric_name}) and $metric_type ne "boolean") {
					MonitisMonitorManager::M3PluginCommon::log_message("warn", "Metric '$metric_name' with regex '$metric_regex' was already parsed!!");
					MonitisMonitorManager::M3PluginCommon::log_message("warn",  "You should fix your script output to have '$metric_regex' only once in the output");
				}
				# push into hash, we'll format it later...
				${$results}{$metric_name} = $data;
			}
		}
	}
}

1;
