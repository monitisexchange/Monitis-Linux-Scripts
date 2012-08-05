package MonitisMonitorManager::Parsing::Regex;
use strict;
use Carp;

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

	# this handles the regex matching
	# TODO will spliting with '\n' work on windows?? - it should...
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
				carp "Matched '$metric_regex'=>'$data' in '$output_line'";
				# yield a warning here if it's already in the hash
				# but don't show it if it's a boolean type :)
				if (defined(${$results}{$metric_name}) and $metric_type ne "boolean") {
					carp "Metric '$metric_name' with regex '$metric_regex' was already parsed!!";
					carp "You should fix your script output to have '$metric_regex' only once in the output";
				}
				# push into hash, we'll format it later...
				${$results}{$metric_name} = $data;
			} elsif ($metric_type eq "boolean") {
				# if the data type is a boolean, and we didn't find the result
				# we were looking for, then it's a 0
				# however if it was already set (as 1 for instance) we won't reset
				# it to 0
				if (not defined(${$results}{$metric_name})) {
					carp "Matched '$metric_regex'=>'0' in '$output_line'";
					${$results}{$metric_name} = 0;
				}
			}
		}
	}
}

1;
