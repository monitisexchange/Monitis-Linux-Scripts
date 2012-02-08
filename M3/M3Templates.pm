#!/usr/bin/perl -w

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

1;
