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
#From plaintext documents
elsif($config{doc_type} eq 'plain') {

    my $files_obj = File::Find::Rule->file()
                                 ->start($config{dir});

    while (my $file = $files_obj->match() ) {

        #print "$file\n";
        if ($file =~ m|\Q$config{ignore_path}\E/*(.*?)([^/]+)$|) {
            my $tid = $1;
            my $du = $2;

            print "\n\nprocessing: dir or tid = $tid file or du = $du\n";
            my $content = read_file($file);
	    resolve->process($tid, $du, html->strip_html($content));
        }


        last;

    }

}
