#!/usr/bin/perl -w

use strict;
use MonitisMonitorManager;
require 'M3Templates.pm';

sub main {
	my $xmlfile = shift @ARGV;

	# if you would like a dry run, i.e. not send anything to Monitis, pass
	# dry_run => 1
	my $M3 = MonitisMonitorManager->new(configuration_xml => $xmlfile);

	# invoke all the agents
	$M3->invoke_agents_loop();
}

&main()
