#!/usr/bin/perl -w

####
#
#  main_'type'.pl file must be moved into /src directory for ace to work
#
####


use warnings;
use strict;

use DBI;
use Cwd;
use Regexp::Common; 
use Lingua::Stem qw(stem);

use IO::File;

use File::Find::Rule;
use File::Slurp;

use Config::General;
#push(@INC, '/home/da_bourq/gitHub/ace/src');
use html;

####
#
# Necessary variables
#
####
my $config_path;
my $pass;


####
#
# resolve MUST be passed the config_path and pass when use resolve is called. It is recommended to initialize $config_path variable here as well.
#
####


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

#optional
if($config{processing} eq 'summary' and $config{doc_type} eq 'email') {

	#do some other kind of post processing on your data, whatever you want, if you want

}


#
#From emails 
elsif($config{doc_type} eq 'example') {


	my $get_du = $dbh_ref->prepare(q{select thread_id, msg_id, subject, body from email});
	$get_du->execute or die "Can't get body from db ", $dbh_ref->errstr;


	while ( my($tid, $du, $subject, $content) = $get_du ->fetchrow_array) {

		$content .= $subject . ' ';
		
		####
		#resolve::process takes as input thread id ($tid) individual msg id ($du) and the body ($content). strip_html is not necessary
		####
		print "\n\nprocessing: tid = $tid email = $du\n";
		resolve::process($tid, $du, html->strip_html($content));
	}
	####
	#
	#resolve::finish MUST be called. inserts only happen in one giant commit at the end, called by resolve::finish
	#
	####
	resolve::finish;



	$get_du->finish;
}

$dbh_ref->disconnect;
