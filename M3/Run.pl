#!/usr/bin/perl -w

use strict;
use MonitisMonitorManager;
require 'M3Templates.pl';

sub main {
	my $xmlfile = shift @ARGV;

	# initialize the agent
	my $M3 = MonitisMonitorManager->new(configuration_xml => $xmlfile);

	# invoke all the agents
	$M3->invoke_agents();
}

&main()
