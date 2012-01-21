#!/usr/bin/perl -w

use MonitisMonitorManager;

sub MonitisMonitorManager::_get_HOSTNAME {
	use Sys::Hostname;
	return hostname;
}

sub main {
	my $xmlfile = shift @ARGV;

	# if you would like a dry run, i.e. not send anything to Monitis, pass
	# dry_run => 1
	my $M3 = MonitisMonitorManager->new(configuration_xml => $xmlfile, dry_run => 1);

	# invoke all the agents
	$M3->invoke_agents_loop();
}

&main()
