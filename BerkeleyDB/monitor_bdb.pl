#!/usr/bin/env perl
############################################################################
# This script creates a Monitis monitor for BerkeleyDB hash-type databases
############################################################################

use strict;
use warnings;

use Monitis;
use Getopt::Long;
use Pod::Usage;

use constant DEBUG => $ENV{MONITIS_DEBUG} || 0;

my $api = undef;

# Get BerkeleyDB environment statistics 
# Param: environment path
# Return: hashref containing stats as key-value pairs
sub getDbStat($) { 
	my ($env) = @_; 
	my %stats;
	my $hitRate;

	# memp_stat() is not available in the BerkeleyDB perl API, so we have to run shell cmd and parse the output
	open OUT, "db_stat -m -h $env| " or die "Could not run db_stat";
	while(<OUT>) { 
		chomp;
		m/^Pool/ && last; # ignore pool file stats
	
		# get cache size
		if( m/Total Cache Size/gio) {
			print "Parsing cache size ...\n" if DEBUG;
			if( $_ =~ m/([0-9]+)KB\s+([0-9]+)B\s+(.+)/) {
				my $cacheSize = $1*1024 + $2;
				print "Cache Size $1:$2|$3|\n" if DEBUG;
				$stats{'Cache Size'} = $cacheSize;
				next; #done parsing this line
			}
		}
		# get hit rate
		if(m/Requested pages found in the cache/gio ) { 
				if( m/\(([0-9]+)%\)/g )  { 
					$hitRate = $1;
				}
				$stats{'Cache Hit Rate'} = $hitRate;
				print "Cache Hit Rate: $hitRate\n" if DEBUG;
				# and go on parsing
		}

		# to ensure unique keys, remove parenthesized values
		s/\(.+\)//go; 

		# anything else, just parse
		if( m/^([0-9]+)\s+(.+)$/gio) { 
			my ($val, $key) = ($1, $2);
			$key =~ s/^\s+//;
			$key =~ s/\s+$//;
			$stats{$key} = $val;
		}
	}
	close OUT;
	return \%stats;
}

# Construct a suitable metric name from text, e.g "Free Hash Buckets" becomes "free_hash_buckets"
#
sub paramName($) { 
		my ($param) = @_;	

		my $name = $param;
		$name =~ tr/[A-Z]/[a-z]/;
		$name =~ s/^the\s+//go;
		$name =~ s/\s+/_/go;
		$name =~ s/\'//go;
	return $name;	
}

# Construct a custom monitor description from a hash containing param names/values
sub makeMonitorSpec($) {
	my ($stats) = @_;
	my $monitorParams = "";

	for my $key (reverse sort keys %$stats) { # keys will appear in reverse order in Monitis UI, so we reverse them here 
		my $paramName = paramName($key);	
		$monitorParams .= "${paramName}:${key}::2;";
	}
	
	$monitorParams =~ s/\;$//go; # get rid of trailing semicolon
	print "Monitor Params: $monitorParams\n" if DEBUG;
	return $monitorParams;	
}

# find an existing monitor. This involves looping through all monitors in monitorGroup; ideally the API should do that for us
# Params: 
# 	monitorName - Monitor Name
# 	monGroup - Monitor Group (aka tag)
sub findMonitorByName($$) { 
	my ($monitorName, $monGroup) = @_;

	my $resp1 = $api->custom_monitors->get(tag=>$monGroup);
	for my $mon ( @$resp1 ) { 
		if($mon->{name} eq $monitorName) { 
			return $mon->{id};
		}
	}
	return undef; # not found

}

# Create a new monitor in a specified monitorGroup
# Param:
# 	monitorDesc - Monitor description
# 	monitorName - Monitor Name. This is how the monitor will appear in Monitis console
# 	monGroup - Monitor Group (tag). This provides a logical monitorGrouping of monitors
sub createMonitor($$$) { 
	my ($monDesc, $monitorName, $monGroup ) = @_;
	print "Creating Monitor $monitorName in Monitor Group $monGroup...\n" if DEBUG;
	my $resp = $api->custom_monitors->add(
	        resultParams => $monDesc,
	        name     => $monitorName,
	        tag      => $monGroup,
	    );

	die "ERROR $resp->{status}" unless $resp->{status} eq 'ok';
	return $resp->{data}
}

# Update statistics in Monitis
# Params: 
# 	monitorId - Monitor ID
# 	stats - hashref containing the Berkeley DB statistics
sub uploadStats($$) { 
	my ($monitorId, $stats) = @_;
	my $results = '';
	for my $key(keys %$stats) { 
		my $newkey = paramName($key);
		$results .= "$newkey:$stats->{$key};";	
	}
	$results =~ s/;$//go; # get rid of trailing semi-colon
	print "Uploading statistics for Monitor ID $monitorId\n" if DEBUG;	
	my $resp = $api->custom_monitors->add_results( 
		monitorId => $monitorId, 
		checktime => time() * 1000,
		results => $results
	);
	die "FAILED: status = $resp->{status}" unless $resp->{status} eq 'ok'; 
}

#
sub error { 
	print STDERR shift, "\n"; 
	pod2usage;
	exit 1;
}
############################ Main script ############################
my $register;
my $envDir; 
my $monitorName; 
my $monitorGroup;
my $monitorId;
my $apiKey; 
my $secretKey;
my $help;

GetOptions(
	"help"   => \$help,
	"register" => \$register,
	"monitorName=s" => \$monitorName,
	"monitorGroup=s" => \$monitorGroup,
	"envDir=s" => \$envDir,
	"monitorId=i" => \$monitorId,
	"apiKey=s" => \$apiKey,
	"secretKey=s" => \$secretKey,
); 

pod2usage(-verbose => 2)  if $help;

error "Options secretKey and apiKey required" unless $apiKey && $secretKey;
error "Option envDir required" unless $envDir; 
error "envDir \'$envDir\' is not a directory" unless ( -d $envDir);

# initialize the Monitis API
$api=Monitis->new(api_key => $apiKey, secret_key => $secretKey) || die "Could not connect to Monitis";

my $stats = getDbStat($envDir); # get Berkeley DB statistics

if( $register ) {  # need to register monitor
	error "Register option requires monitorGroup" unless $monitorGroup;
	error "Register option requires monitorName " unless $monitorName;

	my $monSpec = makeMonitorSpec($stats);

	print "Creating monitor $monitorName in monitorGroup $monitorGroup...\n";
	$monitorId=createMonitor($monSpec,$monitorName, $monitorGroup);
	print "Created monitor with id=$monitorId\n";
} else { # !$register
	if( ! $monitorId ) { # find out monitor Id
		error "Either monitorId or a combination of monitorName AND monitorGroup required" if !($monitorName && $monitorGroup);
		$monitorId = findMonitorByName($monitorName, $monitorGroup);	
	}
} 
print "Uploading statistics for monitor $monitorId...\n";
uploadStats($monitorId, $stats);

__END__

=head1 NAME

monitor_bdb.pl - Monitor BerkeleyDB database environment with Monitis API

=head1 SYNOPSIS

monitor_bdb.pl [--register] --apiKey <api_key> --secretKey <secretKey> --envDir <path_to_env> (--monitorGroup <group> --monitorName <name>) | (--monitorId <monId>)

For help, type 'monitor_bdb.pl -h'

=head1 OPTIONS 

=over 4

=item B<--apiKey>
Your Monitis API key (see Tools -> API -> API Key menu in your Monitis console)

=item B<--secretKey>
Your Monitis secret key (see above)

=item B<--register>
Rregister a new monitor with the specified monitorName and monitorGroup

=item B<--envDir>
Directory containing your BerkeleyDB environment

=item B<--monitorName>
The monitor will appear under this name in the Monitis console

=item B<--monitorGroup>
The monitor will appear in this group in the Monitis console. The group will be created if it does not exist

=item B<--monitorId>
A numeric ID for an existing monitor (cannot be used with --register)

=back 

=head1 DESCIPTION

Upload BerkeleyDB db_stat metrics to Monitis monitor, optionally creating the monitor

=head1 AUTHOR
	
Drago Z Kamenov C<< <dkamenov@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (C) 2006-2012, Monitis Inc.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
