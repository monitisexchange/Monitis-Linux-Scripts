package Parsing::JSON;
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
	my ($self, $monitor_xml_path, $output, $url, $results) = @_;
	# handle JSON pattern matching
	# eval is like a try() catch() block
	eval {
		my $json_presentation = from_json( $output, { utf8  => 1 } );
		$self->match_strings_in_object($monitor_xml_path, $json_presentation, "json", $results);
	};
}

# match a string in the given object
sub match_strings_in_object {
	my ($self, $monitor_xml_path, $presentation, $object_type, $results) = @_;
	foreach my $metric_name (keys %{$monitor_xml_path->{metric}} ) {
		if (defined($monitor_xml_path->{metric}->{$metric_name}->{$object_type}[0])) {
			my $metric_string = $monitor_xml_path->{metric}->{$metric_name}->{$object_type}[0];
			if (defined(eval "\$presentation->$metric_string"))
			{
				my $data = eval "\$presentation->$metric_string";
				carp "Matched '$metric_string'=>'$data'";
				${$results}{$metric_name} = $data;
			}
		}
	}
}

1;
