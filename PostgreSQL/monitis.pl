#!/usr/bin/env perl 
#-d:ptkdb
#Adds results to monitors
###########################################
use constant API_KEY => ''; # MONITIS API_KEY
use constant SECRET_KEY => ''; # MONITIS SECRET_KEY 

my $tag = "SQL Server"; # Monitors tag
my $dbname = "temp123"; #Name of monitoring database
my $dbusername = "root"; #Database username
my $dbpassword = ""; #Database password
my $diskdev = undef;	#name of dev, for read/write monitoring (undef: auto), used /proc/diskstats (example: "sda")
my $db_mountpoint = undef;	#database mountpoint (undef: auto)
##########################################

use Monitis;
use strict qw(vars subs);
use DBI;
use Data::Dumper;
use Sys::Statistics::Linux;
use File::Slurp;
use Proc::ProcessTable;
use File::Basename;
use Sys::Filesystem::MountPoint ':all';


my $tmp_filename_dbread="/tmp/pgmon-dbread.tmp"; #temporary file for "DB read" monitor
my $tmp_filename_diskrw="/tmp/pgmon-diskrw.tmp"; #temporary file for "Disk read write" monitor
my $tmp_filename_trns="/tmp/pgmon-trns.tmp"; #temporary file for "Transactions per second" monitor

my $monitor_ids;my $log_diskprt; my $data_path;
my $dbh = DBI->connect("dbi:Pg:dbname=$dbname","$dbusername","$dbpassword",{PrintError => 0});
if ($DBI::err != 0) {
	print $DBI::errstr . "\n";
	exit($DBI::err);
};

#Get mountpoint of data_directory
if ($db_mountpoint==undef){
	my $sth=$dbh->prepare("SELECT setting AS dd FROM pg_settings WHERE name = 'data_directory'");
	$sth->execute or die $dbh->errstr;
	my $row=$sth->fetchrow_hashref;
	$data_path=$row->{dd};
	$db_mountpoint=path_to_mount_point($data_path);
}

#Get info abot cpu, memory, disks, average load.
my $lxs = Sys::Statistics::Linux->new( cpustats => 1,memstats  => 1,diskusage => 1 , loadavg   => 1);
my $sysinfo  = $lxs->get(1);

&createtmpfiles; #create temporary files for monitors ("DB read" , "Disk read write", "Transactions per second");

my $api = Monitis->new(secret_key => SECRET_KEY, api_key => API_KEY);

#Get array of custom monitors with tag=$tag
my $response = $api->custom_monitors->get(tag => $tag);
#print "Active monitors (tag: $tag):\n";
foreach(@$response){
	  $monitor_ids->{$_->{name}}=$_->{id};
	  #print $_->{name}.": ";
	  #print $_->{id}."\n"
};


#start adding results
&userconn;
&prccpu;
&hitratio;
&sqlsrvmem;
&commitratio;
&dbsize;
&logsize;
&tranpersec;
&db_read;
&diskrw;

$dbh->disconnect();

sub userconn{
	# User connections
	# Checks the current number of connections, and optionally compares it to the maximum allowed, which is determined by the Postgres configuration variable max_connections
	# Example: Give a warning when the number of connections on host quirm reaches 120, and a critical if it reaches 150.
	my $sth=$dbh->prepare("SELECT COUNT(*) as count FROM pg_stat_activity where datname = ?");
	$sth->execute($dbname) or die $dbh->errstr;
	my $row=$sth->fetchrow_hashref;
	my $cnt=$row->{count};
	my $sth=$dbh->prepare("SELECT setting AS mc FROM pg_settings WHERE name = 'max_connections'");
	$sth->execute or die $dbh->errstr;
	my $row=$sth->fetchrow_hashref;
	&addresult({id => $monitor_ids->{"User connections"}, results => "users:".$cnt.";maxusers:".$row->{mc}});
	print "\nUser connections - results added:\n User connections: ".$cnt;
}

sub prccpu{
	#Percent Processor time
	&addresult({id => $monitor_ids->{"Percent Processor Time"}, 
		results => join (";",("total:".$sysinfo->cpustats->{cpu}{total},"user:" .$sysinfo->cpustats->{cpu}{user} ,"system:" . $sysinfo->cpustats->{cpu}{system},"loadavg:" . $sysinfo->loadavg->{avg_1}))});
	print "\nPercent Processor time - results added:\ntotal:" . $sysinfo->cpustats->{cpu}{total} . ";" . "user:" .$sysinfo->cpustats->{cpu}{user} . ";" . "system:" . $sysinfo->cpustats->{cpu}{system}. ";" . "loadavg:" . $sysinfo->loadavg->{avg_1};
}

sub diskrw{
	# Disk read write
	my $first=shift;
	my $disk_read_now; my $disk_write_now;
	my @diskstat_arr=read_file('/proc/diskstats');
	foreach (@diskstat_arr) {
		my $tmp=$_;
		my @tmparr=split (" ",$tmp);
		if (@tmparr[2] eq $diskdev) {$disk_read_now=@tmparr[5];$disk_write_now=@tmparr[9];}
	}
	if ($first!=1) {
		my $cnt=read_file($tmp_filename_diskrw);
		my ($timestmp,$disk_read_old,$disk_write_old)=split(/;/,$cnt);
		my $diff_read=int((((($disk_read_now - $disk_read_old) /(time-$timestmp))*512)/1024)+0.5);
		my $diff_write=int((((($disk_write_now - $disk_write_old) /(time-$timestmp))*512)/1024)+0.5);
		&addresult({id => $monitor_ids->{"Disk read write"}, results => "read:".$diff_read.";write:".$diff_write});
		print "\n\nDisk read write - results added:\n\Read: ".$diff_read."  Write: ".$diff_write;
	}
	write_file($tmp_filename_diskrw, join(";",(time,$disk_read_now,$disk_write_now)));
	
}

sub tranpersec {
	#"Transactions per second
	my $first=shift;
	my $sth=$dbh->prepare('select sum(xact_commit) as count_req from pg_stat_database where datname=?');
	$sth->execute($dbname) or die $dbh->errstr;
	my $row=$sth->fetchrow_hashref;
	if ($first!=1) {
		my $cnt=read_file($tmp_filename_trns);
		my ($timestmp,$count_trn)=split(/;/,$cnt);
		my $diff_trn=int((($row->{count_req} - $count_trn) /(time-$timestmp))+0.5);
		&addresult({id => $monitor_ids->{"Transactions per second"}, results => "committran:".$diff_trn});
		print "\nTransactions per second - results added:\nTransactions per second: $diff_trn\n";
	}
	write_file($tmp_filename_trns,time.";".$row->{count_req});	
}

sub hitratio {
	#Hit ratio
	#Example: Warn if less than 90% in hitratio, and critical if less then 80%.
	my $sth=$dbh->prepare('SELECT
		round(100.*sd.blks_hit/(sd.blks_read+sd.blks_hit), 2) AS dhitratio,
		d.datname
		FROM pg_stat_database sd
		JOIN pg_database d ON (d.oid=sd.datid)
		JOIN pg_user u ON (u.usesysid=d.datdba)
		WHERE sd.blks_read+sd.blks_hit<>0 and d.datname=?');
	$sth->execute($dbname) or die $dbh->errstr;
	my $row=$sth->fetchrow_hashref;
	&addresult({id => $monitor_ids->{"Hit ratio"}, results => "hitratio:".$row->{dhitratio}});
	print "\n\nHit Ratio - results added:\n Hit Ratio: $row->{dhitratio}\n";
}


sub commitratio {
#Checks the commit ratio of all databases and complains when they are too low.	
#Example: Warn if less than 90% in commitratio, and critical if less then 80%.
my $sth=$dbh->prepare('SELECT
		round(100.*sd.xact_commit/(sd.xact_commit+sd.xact_rollback), 2) AS dcommitratio,
		d.datname
		FROM pg_stat_database sd
		JOIN pg_database d ON (d.oid=sd.datid)
		JOIN pg_user u ON (u.usesysid=d.datdba)
		WHERE sd.xact_commit+sd.xact_rollback<>0 and d.datname=?');
	$sth->execute($dbname) or die $dbh->errstr;
	my $row=$sth->fetchrow_hashref;
	&addresult({id => $monitor_ids->{"Commit ratio"}, results => "commitratio:".$row->{dcommitratio}});
	print "\n\nCommit Ratio - results added:\n Commit Ratio: $row->{dcommitratio}\n";
}

sub db_read {
	my $first=shift;
	my $sth=$dbh->prepare('SELECT sum(blks_read) as count_blks,sum(blks_hit) as count_hits FROM pg_stat_database where datname=?');
	$sth->execute($dbname) or die $dbh->errstr;
	my $row=$sth->fetchrow_hashref;	
	if ($first!=1) {
		my $cnt = read_file($tmp_filename_dbread);
		my ($timestmp,$count_blks,$count_hits)=split(/;/,$cnt);
		my $diff_blks=int((($row->{count_blks} - $count_blks) /(time-$timestmp))+0.5);
		my $diff_hits=int((($row->{count_hits} - $count_hits) /(time-$timestmp))+0.5);
		&addresult({id => $monitor_ids->{"DB read"}, results => "blocksread:".$diff_blks.";bufferhits:".$diff_hits});
		print "\nDB read - results added:\nBlocks/sec:".$diff_blks."\nBuffer hits/sec:".$diff_hits;
	};
	write_file($tmp_filename_dbread,join(";",(time,$row->{count_blks},$row->{count_hits})));
	
}

sub sqlsrvmem {
	#SQL Server memory
	my $bypostgresql=0;
	my $bypostgretran=0;
	my $proc = new Proc::ProcessTable;
	
	#my $arrpid=$dbh->selectall_arrayref("select procpid from pg_stat_activity");
	foreach my $p ( @{$proc->table} ){
			if ($p->fname eq "postgres"){$bypostgresql =($bypostgresql+$p->rss)}
			#foreach my $pid(@$arrpid){
			#if ($p->pid==$pid->[0]){$bypostgretran =($bypostgretran+$p->rss);}
	}  
	
	$bypostgresql=($bypostgresql/1024);
	&addresult({id => $monitor_ids->{"SQL Server memory"}, results => join (";",("total:" . $sysinfo->memstats->{memtotal},"used:" . $sysinfo->memstats->{memused},"bypostgresql:".$bypostgresql))});
	print "\nSQL Server memory - results added:\ntotal:" . $sysinfo->memstats->{memtotal}."\nused:" . $sysinfo->memstats->{memused}."\nbypostgresql:".$bypostgresql;
}

sub dbsize {
	my $db_diskprt;
	foreach  my $dkey(keys $sysinfo->diskusage){
		if (($dkey ne 'rootfs') and ($sysinfo->diskusage->{$dkey}{mountpoint} eq $db_mountpoint)){$db_diskprt=$dkey;}
	};
	if ($diskdev==undef){$diskdev=$db_diskprt;$diskdev=~ s/\d+$//;$diskdev=~ /.*\/(.*?)$/;$diskdev=$1;}
	#Database size	and usage
	my $sth=$dbh->prepare("SELECT pg_database_size(?) as dbsize");
	$sth->execute($dbname);
	my $row=$sth->fetchrow_hashref;
	my $dbsize=int(($row->{dbsize}/1024)); 
	&addresult({id => $monitor_ids->{"Database size	and usage"}, results => "total:".$sysinfo->diskusage->{$db_diskprt}{total}.";used:".$sysinfo->diskusage->{$db_diskprt}{usage}.";dbsize:".$dbsize});
	print "\nTest database size - results added:\nTotal:".$sysinfo->diskusage->{$db_diskprt}{total}."\nUsed:".$sysinfo->diskusage->{$db_diskprt}{usage}."\nDbsize:".$dbsize."\n";
}

sub logsize {
	#"Test log size"
	my $sth=$dbh->prepare(q(SELECT pg_ls_dir as filename FROM pg_ls_dir('pg_xlog') WHERE pg_ls_dir ~ E'^[0-9A-F]{24}$' ORDER BY 1));
	$sth->execute();
	my $row=$sth->fetchrow_hashref;
	#$log_filename=$data_path."/".$row->{filename};
	my $log_mountpoint=path_to_mount_point($data_path.$row->{filename});

	my $arrsize=$dbh->selectall_arrayref("SELECT size FROM pg_stat_file('pg_xlog/".$row->{filename}."')");
	my $logsize=0;
	foreach my $size(@$arrsize){$logsize+=($size->[0]/1024);}
	
	#my($logfile,$logpath,$tmp)=fileparse($log_filename);
	#my $ref = df($logpath);
	#my $logsize= -s $log_filename;$logsize=int($logsize/1024);
	
	foreach  my $dkey(keys $sysinfo->diskusage){
		if (($dkey ne 'rootfs') and ($sysinfo->diskusage->{$dkey}{mountpoint} eq $log_mountpoint)){$log_diskprt=$dkey;}
	};
	&addresult({id => $monitor_ids->{"Log size"}, results => "total:".$sysinfo->diskusage->{$log_diskprt}{total}.";used:".$sysinfo->diskusage->{$log_diskprt}{usage}.";logsize:".$logsize});
	print "\nTest log size - results added:\nTotal:".$sysinfo->diskusage->{$log_diskprt}{total}."\nUsed:".$sysinfo->diskusage->{$log_diskprt}{usage}."\nLogsize:".$logsize."\n";

}


sub addresult {
	my $data=shift;
	my $response = $api->custom_monitors->add_results(
		monitorId => $data->{id},
		checktime => time,
		results   => $data->{results},
		
	);
die "Failed add result to $: $response->{status}"
  unless $response->{status} eq 'ok';
}

sub createtmpfiles {
	if ((!-e $tmp_filename_dbread) or (!-e $tmp_filename_trns) or (!-e $tmp_filename_diskrw)) {
		if (!-e $tmp_filename_dbread){
			&db_read(1); warn "first";
		};
		if (!-e $tmp_filename_trns){
			&tranpersec(1);
		}
		if (!-e $tmp_filename_diskrw){
			&diskrw(1);
		}
	sleep(1);
	}
}
