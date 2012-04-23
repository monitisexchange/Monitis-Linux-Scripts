package MonitisMonitorManager::M3PluginCommon;
use strict;
no strict "refs";
require Carp;

# returns the parameter specified or croaks on an error
sub get_mandatory_parameter {
	my ($self, $plugin_xml_base, $parameter_name) = @_;
	# if $parameter_name is undefined, we'll return the string referenced
	# by $plugin_xml_base
	my $xml_path;
	if (defined($parameter_name)) {
		$xml_path = $plugin_xml_base->{$parameter_name}[0];
	} else {
		$xml_path = $plugin_xml_base;
	}

	if (!defined($xml_path)) {
		croak "Parameter '$parameter_name' undefined in plugin '" . $self->name() . "'";
	} else {
		return $xml_path;
	}
}

# returns an optional parameter or undef
sub get_optional_parameter {
	my ($self, $plugin_xml_base, $parameter_name, $default_value) = @_;
	my $return_value = $plugin_xml_base->{$parameter_name}[0];
	if(not defined($return_value) and defined($default_value)) {
		return $default_value;
	} else {
		return $return_value;
	}
}

1;
