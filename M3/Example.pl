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

	# if you would like a dry run, i.e. not send anything to Monitis, pass
	# dry_run => 1
	#my $M3 = MonitisMonitorManager->new(configuration_xml => $xmlfile, dry_run => 1);

	# this will print the templated XML, it'll replace %SOMETHING% with
	# the return value of _get_SOMETHING()
	print $M3->templated_xml();

	# add all the agents in the XML
	$M3->add_agents();

	# invoke all the agents
	$M3->invoke_agents()
}

&main()
