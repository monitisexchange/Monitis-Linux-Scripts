package Parsing::JSON;
use strict;
use Carp;
use Data::Dumper;
use JSON;

sub new {
	my ($class, $name) = @_;
	return undef;
}

# this function identifies the token should be used when parsing
sub name {
	return "json";
}

# matches all XML strings in the given output
sub parse {
	my ($self, $metric_name, $metric_xml_path, $output, $url, $results) = @_;
	# handle JSON pattern matching
	# eval is like a try() catch() block
	eval {
		my $json_presentation = from_json( $output, { utf8  => 1 } );
		$self->match_strings_in_object($metric_name, $metric_xml_path, $json_presentation, "json", $results);
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
