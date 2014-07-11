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

#
#For latifa 
elsif($config{doc_type} eq 'latifa') {

    my $q = qq[select sequence, sec_title, sec_content from $config{table_name}];

    my $get_du = $dbh_ref->prepare($q);

    $get_du->execute or die "Can't get doc units from db ", $dbh_ref->errstr;

    #Stackoverflow
    while ( my($du, $title, $content) = $get_du ->fetchrow_array) {
        my $tid = $du;

        if(defined $title) {
            $content = $title . ' ' . $content;
        }


        print "\n\nprocessing du = $du\n";
	resolve->process($tid, $du, html->strip_html($content));

    }
    $get_du->finish;
}

