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


if($config{doc_type} eq 'stackoverflow') {

	open(my $fh_text, '>', 'text.txt');
	open(my $fh_code, '>', 'code.txt');

	my $q = qq[
                  select parentid, id, title, body, msg_date from                                                                                                                                                              
                  (select id as parentid, id, title, body, creationdate as msg_date from posts 
                    where answercount > 0 and id in (select id from posts where tags ~ E\'$config{tags}\') --the parents (or questions)                                                        
                  union select parentid, id, title, body, creationdate as msg_date from posts 
                    where score > 0 and parentid in (select id from posts where tags ~ E\'$config{tags}\') --the children (answers)                                                   
                    ) as r 
                  order by parentid, msg_date asc
                  ];

	#test
    #$q = q[select parentid, id, title, body, creationdate as msg_date from posts_test limit 10];
	#where id = '29042743'];
	
	my $get_du = $dbh_ref->prepare($q);
    $get_du->execute or die "Can't get doc units from db ", $dbh_ref->errstr;

    my $get_pos_len = $dbh_ref->prepare(qq{select pqn, simple, kind, pos, length(simple) as len, trust_original, snip from clt where trust = 0 and du = ?  order by pos});

	#Stackoverflow
    while ( my($tid, $du, $title, $content) = $get_du ->fetchrow_array) {

        #print STDERR "Link: http://stackoverflow.com/questions/$du\n";
        #test print $title . $content;

        if(defined $title) {
            $content = $title . ' ' . $content;
        } 

        #print "\n\nprocessing du = $du\n";
        my $sc = html->strip_html($content);
		
		# test: print STDERR $sc;
        #process($tid, $du, strip_html($content));

		#$sc = html->remove_code_snips($sc);	

        #print STDERR "$sc\n\n";


    	$get_pos_len->execute($du) or die "Can't get clts from db ", $dbh_ref->errstr;

    	my $old_end = 0;
		my $code;
		my $out;
        while ( my($pqn, $simple, $kind, $pos, $len, $trust_original, $snip) = $get_pos_len->fetchrow_array) {

			#output code to one file
			if ($snip == 0) {
				$code .= $pqn.'_'.$simple.' ';
			}

            #test - print " $old_end, $pos, $len --", substr($sc, $old_end, $pos-$old_end), "\n";
            my $current = substr($sc, $old_end, $pos-$old_end);
			$out .= $current;
            $old_end = $pos+$len;
			#print " $pqn\.$simple ";

		}

        $out .= substr($sc, $old_end, length($sc));

		$out = html->remove_code_snips($out);	

		if (defined $out and length($out) > 1 and defined $code and length($code) > 1) {
			#output English to the other file
			print $fh_text "$out \n";

			#code to the other file 
			print $fh_code "$code \n";
		}


	}
    $get_du->finish;
	$get_pos_len->finish;

	close $fh_text;
	close $fh_code;

}


$dbh_ref->disconnect;

