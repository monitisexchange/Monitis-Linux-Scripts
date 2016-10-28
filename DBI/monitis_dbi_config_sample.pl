#!/usr/bin/perl -w

%CFG = (
	# This is where the monitis API resides, you should change it
	'monitis_api' => {
		'executable' => '../API/monitis_api_wrapper.sh',
	},
	# first monitor, this will be the tag
	'monitors' => {
		'DBI_cakes' => {
			# name of the monitor as it will be displayed on Monitis
			'name' => 'Cake monitor',
			'counters' => {
				'DBI_cakes_number' => {
					# use for db_driver any of 'mysql', 'odbc', 'oracle', etc, refer to:
					# http://cpansearch.perl.org/src/JROBINSON/SQL-Translator-0.11008/lib/SQL/Translator/Parser/DBI.pm
					'db_driver'   => 'mysql',
					# hostname to connect to
					'db_host'     => 'localhost',
					# dataase name to connect to
					'db_name'     => 'test',
					# your credential details (username and password
					'db_username' => 'username',
					'db_password' => 'P4ssw0rd',
					# the query to run
					'db_query'    => 'select count(*) from cakes;',
					# name as it will be displayed on Monitis
					'name'        => 'number of cakes',
					# UOM (Unit of Measurement) as it will be displayed on Monitis
					'UOM'         => 'number of cakes',
				},
			},
		},
		# an example for a monitor with 2 counters, one for pasta dishes and
		# the second for lasagne
		# you can add as many counters under one monitor, and as many monitors
		# as you'd like
		'DBI_italian_food' => {
			'name' => 'Italian food monitor',
			'counters' => {
				'DBI_italian_food_pasta' => {
					'db_driver'   => 'mysql',
					'db_host'     => 'localhost',
					'db_name'     => 'test',
					'db_username' => 'username',
					'db_password' => 'P4ssw0rd',
					'db_query'    => "select count(*) from italian_food where type='pasta';",
					'name'        => 'number of pasta dishes',
					'UOM'         => 'number of pasta dishes',
				},
				'DBI_italian_food_lasagne' => {
					'db_driver'   => 'mysql',
					'db_host'     => 'localhost',
					'db_name'     => 'test',
					'db_username' => 'username',
					'db_password' => 'P4ssw0rd',
					'db_query'    => "select count(*) from italian_food where type='lasagne';",
					'name'        => 'number of pasta dishes',
					'UOM'         => 'number of pasta dishes',
				},
			},
		},
	},
);
