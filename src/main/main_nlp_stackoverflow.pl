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

my $config_path = shift @ARGV;

if (!defined $config_path) {
	$config_path = 'config';
}
die "Config file \'$config_path\' does not exist"
unless (-e $config_path);

my %config =  Config::General::ParseConfig($config_path);

my $dbh_ref = DBI->connect("dbi:Pg:database=$config{db_name}", '', '', {AutoCommit => 0});

#for regenerating the text to dump into nlp pipeline
if($config{doc_type} eq 'stackoverflow') {

	my $q = qq[
                  select parentid, id, title, body, msg_date from                                                                                                                                                              
                  (select id as parentid, id, title, body, creationdate as msg_date from posts 
                    where id in (select id from posts where tags ~ E\'$config{tags}\') --the parents (or questions)                                                        
                  union select parentid, id, title, body, creationdate as msg_date from posts 
                    where parentid in (select id from posts where tags ~ E\'$config{tags}\') --the children (answers)                                                   
                    ) as r 
                  order by parentid, msg_date asc
                  ];

	#test
    $q = q[select parentid, id, title, body, creationdate as msg_date from posts_test where id = '29042743'];
	my $get_du = $dbh_ref->prepare($q);
    $get_du->execute or die "Can't get doc units from db ", $dbh_ref->errstr;

    my $get_pos_len = $dbh_ref->prepare(qq{select pqn, simple, kind, pos, length(simple) as len, trust_original from clt where trust = 0 and du = ?  order by pos});

    my %map_kind = (
        type => '<FONT COLOR="RED">',
        method => '<FONT COLOR="BLUE">',
        variable => '<FONT COLOR="GREEN">',
        field => '<FONT COLOR="ORANGE">',
        package => '<FONT COLOR="yellow">',
        annotation => '<FONT COLOR="purple">',
        enum => '<FONT COLOR="grey">',
        annotation_package => '<FONT COLOR="purple">',
    );

    my $end_kind = '</FONT>';

    #Stackoverflow
    while ( my($tid, $du, $title, $content) = $get_du ->fetchrow_array) {

        #print "Link: http://stackoverflow.com/questions/$du\n";
        #print $title . $content;

        if(defined $title) {
            $content = $title . ' ' . $content;
        } 

        #print "\n\nprocessing du = $du\n";
        my $sc = html->strip_html($content);
        #print STDERR "$sc\n\n";
        #process($tid, $du, strip_html($content));


        $get_pos_len->execute($du) or die "Can't get clts from db ", $dbh_ref->errstr;

        print "<br><a href=\"http://stackoverflow.com/questions/$du\">Post: $du</a>\n<br>";
        my $old_end = 0;
        while ( my($pqn, $simple, $kind, $pos, $len, $trust_original) = $get_pos_len->fetchrow_array) {
            #test - print " $old_end, $pos, $len --", substr($sc, $old_end, $pos-$old_end), "\n";
            my $current = substr($sc, $old_end, $pos-$old_end);
            print html->code_snips_to_html($current);
            $old_end = $pos+$len;
            #test - print " $old_end, $pos -- prxh_$kind\{$pqn\.$simple\} \n";

		#	if ($trust_original > 0 and ($kind eq 'method' or $kind eq 'field') ) {
				print " $map_kind{$kind}$pqn\.$simple$end_kind ";
#			}
#			else {
#				print " $map_kind{$kind}$pqn$end_kind ";
#			}
        }

        print html->code_snips_to_html(substr($sc, $old_end, length($sc)));
        print "<br><a href=\"http://stackoverflow.com/questions/$du\">Post: $du</a><br>\n";

    }
    $get_du->finish;
	$get_pos_len->finish;
}

$dbh_ref->disconnect;

