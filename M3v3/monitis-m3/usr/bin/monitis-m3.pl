#!/usr/bin/perl -w

use strict;
use Getopt::Long;
use MonitisMonitorManager;

my $monitis_config_dir = "/etc/m3.d";
defined($ENV{M3_CONFIG_DIR}) and $monitis_config_dir = $ENV{M3_CONFIG_DIR};
require "$monitis_config_dir/M3Templates.pm";

sub usage {
	my $command = $0;
	$command =~ s#^.*/##;
	print "$command [--dry-run] [--once] [--help] configuration.xml\n";
	exit;
}

sub main {
	my $dry_run = 0;
	my $once = 0;
	my $help = 0;
	GetOptions("dry-run" => \$dry_run, "once" => \$once, "help" => \$help);
	if ($help) {
		usage();
	}

	my $xmlfile = shift @ARGV;

	# if you would like a dry run, i.e. not send anything to Monitis, pass
	# dry_run => 1
	my $M3 = MonitisMonitorManager->new(configuration_xml => $xmlfile, dry_run => $dry_run);

	# invoke all the agents
	if ($once == 1) {
		$M3->invoke_agents();
	} else {
		$M3->invoke_agents_loop();
	}
}

&main()
