package MonitisMonitorManager::Compute::Math;
use strict;
use Carp;

sub new {
	my ($class, $name) = @_;
	return undef;
}

# this function identifies the token should be used when parsing
sub name {
	return "math";
}

# perform a simple computation on the values provided
sub compute {
	my ($self, $agent_name, $monitor_name, $monitor_xml_path, $code, $results) = @_;
	foreach my $metric_name (keys %{$results}) {
		my $computed_value = eval "${$results}{$metric_name} $code";
		carp "Evalutaing '$metric_name' = '${$results}{$metric_name} $code' == '$computed_value'";
		${$results}{$metric_name} = $computed_value;
	}
}

1;
