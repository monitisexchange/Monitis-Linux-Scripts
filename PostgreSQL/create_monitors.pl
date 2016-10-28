#!/usr/bin/env perl
#Creates page and monitors
use Monitis;
use strict;
######################################
use constant API_KEY => ''; # MONITIS API_KEY
use constant SECRET_KEY => ''; # MONITIS SECRET_KEY 

my $page_title = "SQL Server"; # Page title
my $tag = "SQL Server";# Monitors tag
######################################

my $api =Monitis->new(secret_key => SECRET_KEY, api_key => API_KEY);     
my $columns = "2";

#Add page
my $response = $api->layout->add_page(
	title       => $page_title,
	columnCount => $columns
);
die "Failed to add page: $response->{status}"
  unless $response->{status} eq 'ok';

my $page_id=$response->{data}->{pageId};

#Adds custom monitors:

#% Processor Time
&add_custmon({ monitorParams => 'Processor:ProcessorUtil:PrcProcessorTime:3:false',
				resultParams => 'total:Total:N/A:2;user:User:N/A:2;system:System:N/A:2;loadavg:LoadAvg:N/A:2',
				name => 'Percent Processor Time',
				row => 1,
				column => 1,
				tag => $tag});


#% Disk read write per second
&add_custmon({ monitorParams => 'Disk:Disk utilization:Disk util:3:false;',
				resultParams => 'read:Read/sec:N/A:2;write:Write/sec:N/A:2;',
				name => 'Disk read write',
				row => 1,
				column => 2,
				tag => $tag});
				

#'Transactions per second
&add_custmon({ monitorParams => 'Tran:Transactions/sec:tran/sec:3:false;',
				resultParams => 'committran:Commited transactions/sec:N/A:2;',
				name => 'Transactions per second',
				row => 2,
				column => 1,
				tag => $tag});

#'Hit ratio
&add_custmon({ monitorParams => 'hitratio:Hit ratio:hitratio:3:false;',
				resultParams => 'hitratio:Hit ratio:N/A:2;',
				name => 'Hit ratio',
				row => 2,
				column => 2,
				tag => $tag});

#'Commit ratio
&add_custmon({ monitorParams => 'commitratio:Commit ratio:commitratio:3:false;',
				resultParams => 'commitratio:Commit ratio:N/A:2;',
				name => 'Commit ratio',
				row => 3,
				column => 1,
				tag => $tag});

#'Page lookups
#&add_custmon({ monitorParams => 'pagelookups:Page lookups:pagelookups:3:false;',
				#resultParams => 'lookups:lookups:N/A:2;',
				#name => 'Page lookups',
				#row => 3,
				#column => 2,
				#tag => $tag});

#'DB Read per second
# total disk blocks read, and total buffer hits 
&add_custmon({ monitorParams => 'blocksRead:Blocks read:blocksRead:3:false;',
				resultParams => 'blocksread:Blocks read/sec:N/FA:2;bufferhits:Buffer Hits/sec:N/FA:2',
				name => 'DB read',
				row => 3,
				column => 2,
				tag => $tag});

#'User connections
&add_custmon({ monitorParams => 'users:User connections:users:3:false;',
				resultParams => 'users:users:N/A:2;maxusers:max_users:N/A:2',
				name => 'User connections',
				row => 4,
				column => 1,
				tag => $tag});

#'SQL Server Memory
&add_custmon({ monitorParams => 'sqlmemory:SQL Server memory:sqlmemory:3:false;',
				resultParams => 'total:Total KB:N/A:2;used:Used KB:N/A:2;bypostgresql:Used by server KB:N/A:2;',
				name => 'SQL Server memory',
				row => 4,
				column => 2,
				tag => $tag});
				
	
#'Database size	and usage		
&add_custmon({ monitorParams => 'TestDBSize:Test database size:TestDBSize:3:false;',
				resultParams => 'total:Total KB:N/A:2;used:Used KB:N/A:2;dbsize:Database size KB:N/A:2;',
				name => 'Database size	and usage',
				row => 5,
				column => 1,
				tag => $tag});

#'Log size and usage
&add_custmon({ monitorParams => 'TestLogSize:Test log size:TestLogSize:3:false;',
				resultParams => 'total:Total KB:N/A:2;used:Used KB:N/A:2;logsize:Log size KB:N/A:2;',
				name => 'Log size',
				row => 5,
				column => 2,
				tag => $tag});

print "\nPage and monitors created.\n";				
sub add_custmon {
	my $data=shift;
	my $response = $api->custom_monitors->add(
		monitorParams => $data->{monitorParams},
		resultParams => $data->{resultParams},
		name => $data->{name},# : 
		tag => $data->{tag},
		
	);
	die "Failed to add custom monitor \"$data->{name}\": $response->{status}"
	unless $response->{status} eq 'ok';
	my $test_id=$response->{data};
	
	my $response = $api->layout->add_module_to_page(
        moduleName => 'CustomMonitor',
        pageId     => $page_id,
        column     => $data->{column} ,
        row        => $data->{row},
        dataModuleId => $test_id
	);
	die "Failed to dd_module_to_page \"$data->{name}\": $response->{status}"
	unless $response->{status} eq 'ok';
}

