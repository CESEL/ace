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
#For stackoverflow
if($config{doc_type} eq 'stackoverflow') {

    #my $get_du = $dbh_ref->prepare(qq[select parentid, p.id, title, body, p.creationdate as msg_date, owneruserid as nickname, displayname as name, emailhash as email from posts p, users u where owneruserid = u.id and parentid in (select id from posts where tags ~ E\'$config{tags}\') order by parentid, p.creationdate asc]);

    #instead of old query above which modifies stackoverflow tables, we union the parents and the children (parents don't have a parentid) 
    my $q = qq[
                  select parentid, id, title, body, msg_date from                                                                                                                                                              
                  (select id as parentid, id, title, body, creationdate as msg_date from posts 
                    where id in (select id from posts where tags ~ E\'$config{tags}\') --the parents (or questions)                                                        
                  union select parentid, id, title, body, creationdate as msg_date from posts 
                    where parentid in (select id from posts where tags ~ E\'$config{tags}\') --the children (answers)                                                   
                    ) as r 
                  order by parentid, msg_date asc
                  ];

#    #lucene is implemented in all kinds of languages, so need complex regexp
#    my $q = q[
#                  select parentid, id, title, body, msg_date from                                                                                                                                                              
#                  (select id as parentid, id, title, body, creationdate as msg_date from posts 
#                    where id in (select id from posts where tags ~ E'lucene' and (tags ~ E'java' or tags !~ E'net|c#|php|nhibernate|zend|clucene|ruby|c\\\\+\\\\+|pylucene|python|rails')) 
#                  union select parentid, id, title, body, creationdate as msg_date from posts 
#                    where parentid in (select id from posts where tags ~ E'lucene' and (tags ~ E'java' or tags !~ E'net|c#|php|nhibernate|zend|clucene|ruby|c\\\\+\\\\+|pylucene|python|rails')) 
#                    ) as r 
#                  order by parentid, msg_date asc
#                  ];

    my $get_du = $dbh_ref->prepare($q);



    $get_du->execute or die "Can't get doc units from db ", $dbh_ref->errstr;

    #Stackoverflow
    while ( my($tid, $du, $title, $content) = $get_du ->fetchrow_array) {

        if(defined $title) {
            $content = $title . ' ' . $content;
        }


        print "\n\nprocessing du = $du\n";
	resolve::process($tid, $du, html->strip_html($content));

    }
    resolve::finish;
    $get_du->finish;
}
