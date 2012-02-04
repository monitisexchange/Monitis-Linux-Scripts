package Parsing::LineNumber;
use strict;
use Carp;
use Data::Dumper;

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
	my ($self, $monitor_xml_path, $output, $output_command, $results) = @_;
	my $line_number = 1;
	# this handles the regex matching
	# TODO will spliting with '\n' work on windows?? - it should...
	foreach my $output_line ( split ('\n', $output) ) {
		# look for each metric on each line
		foreach my $metric_name (keys %{$monitor_xml_path->{metric}} ) {
			if (defined($monitor_xml_path->{metric}->{$metric_name}->{$self->name()}[0])) {
				my $metric_line_number = $monitor_xml_path->{metric}->{$metric_name}->{$self->name()}[0];
				my $metric_type = $monitor_xml_path->{metric}->{$metric_name}->{type}[0];
				if ($metric_line_number == $line_number) {
					chomp $output_line;
					my $data = $output_line;
					if ($metric_type eq "boolean") {
						# if it's a boolean, use a positive value instead of
						# the extracted value
						$data = 1;
					} else {
						# if it's not a boolean type, use the extracted data
						my $data = $output_line;
					}
					carp "Matched '$metric_line_number'=>'$data' in '$output_line'";
					# yield a warning here if it's already in the hash
					if (defined(${$results}{$metric_name})) {
						carp "Metric '$metric_name' with line number '$metric_line_number' was already parsed!!";
						carp "You should fix your script output ('$output_command') to have '$metric_line_number' only once in the output";
					}
					# push into hash, we'll format it later...
					${$results}{$metric_name} = $data;
				} elsif ($metric_type eq "boolean") {
					# if the data type is a boolean, and we didn't find the result
					# we were looking for, then it's a 0
					carp "Matched '$metric_line_number'=>'0' in '$output_line'";
					${$results}{$metric_name} = 0;
				}
			}
		}
		$line_number++;
	}
}

1;
