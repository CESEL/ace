#!/usr/bin/perl -w

use warnings;
use strict;

use DBI;
use Config::General;
use XML::Simple;
use Data::Dumper;

my $config_path = shift @ARGV;

if (!defined $config_path) {
	$config_path = 'config';
}
die "Config file \'$config_path\' does not exist"
	unless (-e $config_path);

my %config =  Config::General::ParseConfig($config_path);

my $dbh_ref = DBI->connect("dbi:Pg:database=$config{db_name}", '', '', {AutoCommit => 0});

my $insert = $dbh_ref->prepare(q{insert into posts values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)});

my $xml = new XML::Simple;

my $cnt = 0;
while (my $line = <>) {
	if ($line =~ /^\s*<row/) {
		my $data = $xml->XMLin($line);
		print Dumper($data);
		$cnt ++;
	}
	
	if ($cnt > 0) {
		last;
	}
}

	


