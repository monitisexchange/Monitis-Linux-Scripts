package Execution::Perl;
use strict;
use Carp;
use Data::Dumper;
use File::Temp qw/tempfile tempdir/;

sub new {
	my ($class, $name) = @_;
	return undef;
}

# this function identifies the token should be used when parsing
sub name {
	return "perl";
}

# execute perl code executable and return the output
sub execute {
	my ($self, $monitor_xml_path, $code, $results) = @_;
	my ($fh, $perl_filename) = tempfile();
	print $perl_filename . "\n";
	print $fh $code;
	my $output = qx{ perl -- $perl_filename } || carp "Failed running '$perl_filename': $!" && return "";
	unlink($perl_filename);
	return $output;
}

# we can add extra counters in this function, such as statistics etc.
# for this simple executable - we add none
sub extra_counters_cb {
	return "";
}

1;
