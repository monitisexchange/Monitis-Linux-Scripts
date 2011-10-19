#!/usr/bin/perl -w

use MonitisMonitorManager;

sub MonitisMonitorManager::_get_HOSTNAME {
	use Sys::Hostname;
	return hostname;
}

sub main {
	my $xmlfile = shift @ARGV;

	# initialize the agent
	my $M3 = MonitisMonitorManager->new(configuration_xml => $xmlfile);

	# invoke all the agents
	$M3->invoke_agents();
}

&main()
