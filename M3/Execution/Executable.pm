package Execution::Executable;
use Carp;
use Data::Dumper;

sub new {
	my ($class, $name) = @_;
	return undef;
}

# this function identifies the token should be used when parsing
sub name {
	return "exectemplate";
}

# execute an executable and return the output
sub execute {
	my ($self, $monitor_xml_path, $executable, $results) = @_;

	# running with qx{} as it should run also on windows
	$output = qx{ $executable } || croak "Failed running '$executable': $!";
	return $output;
}

1;
