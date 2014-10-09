#!/usr/bin/perl -w

use warnings;
use strict;

use DBI;
use Cwd;
use Regexp::Common; 

use IO::File;

use File::Find::Rule;
use File::Slurp;

use Config::General;
use html;

my $config_path;

#two passes, find trustued code elements, then reparse to pull out all ces
my $pass;

	
use resolve ($config_path=shift, $pass=shift);
if (!defined $pass) {
	$pass = 'first';
}

if (!defined $config_path) {
	$config_path = 'config';
}
die "Config file \'$config_path\' does not exist"
unless (-e $config_path);


my %config =  Config::General::ParseConfig($config_path);

my $dbh_ref = DBI->connect("dbi:Pg:database=$config{db_name}", '', '', {AutoCommit => 0});
#tutorial
elsif($config{doc_type} eq 'tutorial') {

    my $db_check_repo_ref = $dbh_ref->prepare(q{select tid from clt where tid = ? group by tid});
    resolve->process_dir($config{path}, \%config, $db_check_repo_ref);
    $db_check_repo_ref->finish;
}
else {
    print STDERR "Invalid doc_type ", $config{doc_type};
}

