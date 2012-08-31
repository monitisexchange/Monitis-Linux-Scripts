package MonitisMonitorManager::M3Logger;
use MonitisMonitorManager;
use strict;
use Data::Dumper;
use Carp;
use Sys::Syslog;

my $instance;

sub instance {
	unless (defined $instance) {
			my $type = shift;
			my $this = {
				syslog => 0,
		};
		openlog("M3", 0, "local1");
		$instance = bless $this, $type;
	}

	return $instance;
}

# destructor
sub DESTROY {
	my $self = shift;

	# close the syslog logging facility
	closelog();
}

sub set_syslog_logging {
        my ($self, $syslog_logging) = @_;
	$self->{syslog} = $syslog_logging;
}

# log a message
sub log_message {
        my ($self, $priority, $message) = @_;
	if ($self->{syslog} == 1) {
		syslog($priority, "%s", $message);
	} else {
		carp $message;
	}
}

1;
