package MonitisMonitorManager::Parsing::LineNumber;
use MonitisMonitorManager::M3PluginCommon;
use strict;

sub new {
	my ($class, $name) = @_;
	return undef;
}

# this function identifies the token should be used when parsing
sub name {
	return "line";
}

# matches regexes the user defined
sub parse {
	my ($self, $metric_name, $metric_xml_path, $output, $results) = @_;
	my $line_number = 1;

	# if metric is boolean, set it to false, then set to true if
	# anything was found...
	my $metric_type = $metric_xml_path->{type}[0];
	if ($metric_type eq "boolean") {
		# if the data type is a boolean, and we didn't find the result
		# we were looking for, then it's a 0
		${$results}{$metric_name} = "false";
	}

	# this handles the regex matching
	# spliting with [\r\n]+ should work on windows...
	foreach my $output_line ( split /[\r\n]+/, $output ) {
		# look for each metric on each line
		if (defined($metric_xml_path->{$self->name()}[0])) {
			my $metric_line_number = $metric_xml_path->{$self->name()}[0];
			if ($metric_line_number == $line_number) {
				chomp $output_line;
				my $data = $output_line;
				if ($metric_type eq "boolean") {
					# if it's a boolean, use a positive value instead of
					# the extracted value
					$data = "true";
				} else {
					# if it's not a boolean type, use the extracted data
					my $data = $output_line;
				}
				MonitisMonitorManager::M3PluginCommon::log_message("debug", "Matched '$metric_line_number'=>'$data' in '$output_line'");
				# yield a warning here if it's already in the hash
				if (defined(${$results}{$metric_name}) and $metric_type ne "boolean") {
					MonitisMonitorManager::M3PluginCommon::log_message("warn", "Metric '$metric_name' with line number '$metric_line_number' was already parsed!!");
					MonitisMonitorManager::M3PluginCommon::log_message("warn", "You should fix your script output to have '$metric_line_number' only once in the output");
				}
				# push into hash, we'll format it later...
				${$results}{$metric_name} = $data;
			}
		}
		$line_number++;
	}
}

1;
