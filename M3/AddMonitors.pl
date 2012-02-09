#!/usr/bin/perl -w

use strict;
use MonitisMonitorManager;
require 'M3Templates.pm';

sub main {
	my $xmlfile = shift @ARGV;

	# initialize the agent
	my $M3 = MonitisMonitorManager->new(configuration_xml => $xmlfile);

	# add all the agents in the XML
	$M3->add_agents();
}

&main()
