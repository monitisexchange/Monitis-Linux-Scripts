#!/usr/bin/perl -w
use Carp;

sub MonitisMonitorManager::_get_HOSTNAME {
	use Sys::Hostname;
	return hostname;
}

sub MonitisMonitorManager::_get_PGSQL_DEVICE {
	return "sda1";
	use Sys::Hostname;
	return hostname;
}

sub MonitisMonitorManager::_get_PGSQL_DB_NAME {
	return "postgres";
}

sub MonitisMonitorManager::_get_API_KEY {
	# remove croak line after you replace the XXX with your API key
	return "xxx";
}

sub MonitisMonitorManager::_get_SECRET_KEY {
	# remove croak line after you replace the XXX with your secret key
	return "xxx";
}

1;
