package Parsing::XPath;
use strict;
require Carp;

sub new {
	my ($class, $name) = @_;
	return undef;
}

# this function identifies the token should be used when parsing
sub name {
	return "xpath";
}

# matches all XML strings in the given output
sub parse {
	my ($self, $metric_name, $metric_xml_path, $output, $results) = @_;
	# handle XML pattern matching
	# eval is like a try() catch() block
	eval {
		my $xml_parser = XML::Simple->new(ForceArray => 1);
		# do not use XMLin() as it might look for a file, parse_string()
		# is much better so we can avoid potential error messages
		my $xml_presentation = $xml_parser->parse_string($output);
		$self->match_strings_in_object($metric_name, $metric_xml_path, $xml_presentation, "xpath", $results);
	};
}

# match a string in the given object
sub match_strings_in_object {
	my ($self, $metric_name, $metric_xml_path, $presentation, $object_type, $results) = @_;
	if (defined($metric_xml_path->{$object_type}[0])) {
		my $metric_string = $metric_xml_path->{$object_type}[0];
		if (defined(eval "\$presentation->$metric_string"))
		{
			my $data = eval "\$presentation->$metric_string";
			carp "Matched '$metric_string'=>'$data'";
			${$results}{$metric_name} = $data;
		}
	}
}

1;
