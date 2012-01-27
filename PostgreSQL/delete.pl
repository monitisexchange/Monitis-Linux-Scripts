#!/usr/bin/perl
#deletes page "SQL Server" and all custom monitors with same tag
use Monitis;
use strict;

#########################################
use constant API_KEY => ''; # MONITIS API_KEY
use constant SECRET_KEY => ''; # MONITIS SECRET_KEY 
my $tag = "SQL Server"; # Monitors tag
#########################################


my $idpage;
my $api =Monitis->new(secret_key => SECRET_KEY, api_key => API_KEY);

#Get array of custom monitors with tag=$tag
my $response = $api->custom_monitors->get(tag => $tag);

#Deletes all monitors in array
foreach(@$response){$api->custom_monitors->delete(monitorId => $_->{id})};

#Get array of pages 
my $response = $api->layout->get_pages;
foreach(@$response){$idpage->{$_->{title}}=$_->{id};};

#delete page with pageId="SQL Server"
my $response = $api->layout->delete_page(pageId => $idpage->{"SQL Server"});
my $response = $api->layout->get_pages;

print "Page and monitors deleted.\n";
print "\nPages:\n";
foreach(@$response){print $_->{title};print $_->{id}."\n"};

