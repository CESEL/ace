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

use Text::Ngrams;
use Text::Document;
use File::Basename;
use String::CamelCase qw(camelize decamelize wordsplit);
use String::Trim;
use Lingua::StopWords qw(getStopWords);
use Path::Class;




sub rm_squiggly{

	my ($start) = $_[1];
	for (my $i = $start + 1; $i < length($_[0]); $i++){
		if (substr($_[0], $i, 1) eq '{'){
			rm_squiggly($_[0], $i);
		}
		if (substr($_[0], $i, 1) eq '}'){
			substr($_[0], $start, $i - $start + 1) = "";
			last;
		}	
	}
}

sub rm_round{

	my ($start) = $_[1];
	for (my $i = $start + 1; $i < length($_[0]); $i++){
		if (substr($_[0], $i, 1) eq '('){
			rm_round($_[0], $i);
		}
		if (substr($_[0], $i, 1) eq ')'){
			substr($_[0], $start, $i - $start + 1) = "";
			last;
		}	
	}
}

sub rm_square{

	my ($start) = $_[1];
	for (my $i = $start + 1; $i < length($_[0]); $i++){
		if (substr($_[0], $i, 1) eq '['){
			rm_square($_[0], $i);
		}
		if (substr($_[0], $i, 1) eq ']'){
			substr($_[0], $start, $i - $start + 1) = "";
			last;
		}	
	}
}

#removes lines of code, dates, time etc.
sub clean_body{

	my ($body) = @_;
	#remove squiggly brackets
	for (my $i = 0; $i < length($body); $i++){
		if (substr($body, $i, 1) eq '{'){
			rm_squiggly($body,$i);
		}
	}

	#remove round brackets
	for (my $i = 0; $i < length($body); $i++){
		if (substr($body, $i, 1) eq '('){
			rm_round($body,$i);
		}
	}

	#remove square brackts
	for (my $i = 0; $i < length($body); $i++){
		if (substr($body, $i, 1) eq '['){
			rm_square($body,$i);
		}
	}

	#remove point concatinated
	$body =~ s/( \S+? (\.\S+){2,}?  )//gxe;
		
	#remove / concatinated
	$body =~ s/( \S+? (\/\S+){2,}?  )//gxe;
	
	#remove _ concatinated
	$body =~ s/( \S+? (_\S+){2,}?  )//gxe;
	
	#remove attachments
	$body =~ s/Attachment: HADOOP-\S+?\s//g;
	
	#remove web address
	$body =~ s/(http|https):\/\/\S+?\s//g;
	
	#Content type: something
	$body =~ s/Content-Type: \S+?\s//g;
	
	#charset="something"
	$body =~ s/charset="\S+?"\s//g;
	
	#Content-Transfer-Encoding: something
	$body =~ s/Content-Transfer-Encoding: \S+?\s//g;
	
	#lines starting with two or more dashes --....
	$body =~ s/(^|\s)--\S+?\s//g;	
	
	#remove filetypes, .jar .java etc
	$body =~ s/(\.jar|\.java|\.xml|)//g;

	#remove numbers and punctuation
	$body =~ s/[\d\$#@~!&*;,?^'=:<>%\+\."\/\(\)\{\}\[\]]+//g;

	$body =~ tr|-| |;

	#remove <stuff..>
	$body =~ s/<[^>]*\>//g;


	$body =~ s/\h+/ /g;
	

	return $body;
							
}

#nlp techniques
sub remove_stop_words{

	my ($body) = @_;
	$body = lc($body);
	my $stopwords = getStopWords('en');
	my @words = split(' ', $body);
	my $scalartext = join ' ', grep {!$stopwords -> {$_} } @words;
	$scalartext =~ s/\h+/ /g;
	return $scalartext;
}

#wordsplit
sub split_words{
	
	my ($body) = @_;
	$body =~ s/\h+/ /g;
	my @arrayAll;
	my @scalarArray = split (' ', $body);
	foreach my $word (@scalarArray){
		my @array = wordsplit($word);
		push(@arrayAll, @array);
	}
	
	my $splittext = join ' ', @arrayAll;
	return $splittext;
}


#remove java and common keywords
sub remove_java{
	
	my ($body) = @_;
	my @body_list = split(' ', $body);
	my $filename = "files/common_words2.txt";
	
	open(FILE, $filename) or die ("could not open file");
	my %stop = ();
	my @commonWords;
	foreach my $line (<FILE>){
		chomp $line;
		push(@commonWords, $line);
	}
	close(FILE);
	%stop = map { lc $_ => 1} @commonWords;

	my (@ok, %seen);
	foreach my $word (@body_list){
		push @ok, $word unless $stop{lc $word} or $seen{lc $word}++;
	}
	$body = join ' ', @ok;
	return $body;
}

#generate ngrams
sub getnGram{
	my ($body) = @_;
	my $nGramSize = 5;
	my $nGramOrderCriteria = 'frequency';
	my $onlyFirst = 30;
	my $normalizeFrequency = 0;
	my $onlyMostFrequentng = 1;
	my $type = 'word';
	my $nGram = Text::Ngrams -> new ( windowsize => $nGramSize, type => $type);
	$nGram -> process_text($body);
	my $n_gram = $nGram -> to_string(orderby => $nGramOrderCriteria, onlyfirst => $onlyFirst, normalize => $normalizeFrequency, spartan => $onlyMostFrequentng);
	return $n_gram;
}

if($config{processing} eq 'summary' and $config{doc_type} eq 'email') {
	#my $get_pos_len = $dbh_ref->prepare(qq{select du, pqn, simple, kind, pos, length(simple) as len from clt where trust = 0 and kind <> 'variable' and du = '1035654119.30.1388136223004.JavaMail.hudson\@aegis' order by du, pos});
	my $get_pos_len = $dbh_ref->prepare(qq{select du, pqn, simple, kind, pos, length(simple) as len from clt where simple = 'JobTracker' order by du, pos});
	my $get_du = $dbh_ref->prepare(q[select thread_id, msg_id, subject, body from email where msg_id = ?]);
	my $get_email = $dbh_ref->prepare(q[select thread_id, msg_id, subject, body from email limit 100]);

	#my $get_simple = $dbh_ref->prepare(q[select simple from clt where du = '?']);

	$get_pos_len->execute or die;
   
	my $body;
	my $ngram;
	my @all_body;
	my @all_original_body;
	my $final_body;


	#while(my ($du, $pqn, $simple, $kind, $pos, $len) = $get_pos_len->fetchrow_array){
				
		$get_email->execute or die "Can't get body from db ", $dbh_ref->errstr;
		while(my($thread_id, $msg_id, $subject, $body) = $get_email->fetchrow_array){
			if (defined $subject){
				$body .= $subject . ' ';
			}
			my $original_body = $body;
			$body = html->strip_html($body);	

			$body = split_words($body);

			$body = clean_body($body);

			#if ($body !~ /$simple/) {
			#	next;
			#}

			$body = remove_stop_words($body);
	
			$body = remove_java($body);
		
			#push(@all_original_body, $original_body);
			#push(@all_body, $body);
			my $dir = dir("/home/da_bourq/Desktop/test");
			my $filename = $dir -> file("$msg_id".".txt");
		
			open (my $fh, '>', $filename);
			print $fh $body;
			close $fh;


		#$ngram = getnGram($more_body);	

		#print "ORIGINAL:\n$body\n\nFIRSTPASS:\n$clean_body\n\nSECONDPASS\n$cleaner_body\n\nTHIRDPASS\n$more_body\n\n";
	
		

		#if ($pqn !~ /.*\..*/){
		#	print "pqn: ".$pqn."\n"."simple: ".$simple."\n"."we get: ".substr($sc, $pos, $len)."\n\n";
			
		#}
	}
	
	#$final_body = join ' ', @all_body;
	#my $final_original_body = join ' ', @all_original_body;
	#print $final_original_body;
	#$ngram = getnGram($final_body);
	#print $ngram;

}


#
#From emails 
elsif($config{doc_type} eq 'email') {


    my $get_du = $dbh_ref->prepare(q{select thread_id, msg_id, subject, body from email});
    $get_du->execute or die "Can't get body from db ", $dbh_ref->errstr;

   
    while ( my($tid, $du, $subject, $content) = $get_du ->fetchrow_array) {

	    $content .= $subject . ' ';

            print "\n\nprocessing: tid = $tid email = $du\n";
	    resolve->process($tid, $du, html->strip_html($content));
        }
	resolve->finish;
}

