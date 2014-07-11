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


#testing purposes -> feed a file: e.g., dealwiththis.txt
if($config{doc_type} eq 'test') {
    my $content;
    my $title;
    while (<>) {
        $content .= $_;
    }

    if (defined $content) {
        my $tid = 'test_thread';
        my $du = 'test_du';

        print "\n\nprocessing du = $du\n";
	resolve->process($tid, $du, html->strip_html($content));
    }
}

elsif($config{processing} eq 'summary' and $config{doc_type} eq 'email') {
	#my $get_pos_len = $dbh_ref->prepare(qq{select du, pqn, simple, kind, pos, length(simple) as len from clt where trust = 0 and kind <> 'variable' and du = '1035654119.30.1388136223004.JavaMail.hudson\@aegis' order by du, pos});
	my $get_pos_len = $dbh_ref->prepare(qq{select du, pqn, simple, kind, pos, length(simple) as len from clt where simple = 'JobTracker' order by du, pos});
	my $get_du = $dbh_ref->prepare(q[select thread_id, msg_id, subject, body from email where msg_id = ?]);

	#my $get_simple = $dbh_ref->prepare(q[select simple from clt where du = '?']);

	$get_pos_len->execute or die;
   
	my $body;
	my $ngram;
	my @all_body;
	my @all_original_body;
	my $final_body;


	while(my ($du, $pqn, $simple, $kind, $pos, $len) = $get_pos_len->fetchrow_array){
				
		$get_du->execute($du) or die "Can't get body from db ", $dbh_ref->errstr;
		my($thread_id, $du, $subject, $body) = $get_du->fetchrow_array;
		if (defined $subject){
			$body .= $subject . ' ';
		}
		my $original_body = $body;
		$body = html->strip_html($body);	

		#$body = split_words($body);

		$body = clean_body($body);

		if ($body !~ /$simple/) {
			next;
		}

		$body = remove_stop_words($body);
	
		$body = remove_java($body);
		
		push(@all_original_body, $original_body);
		push(@all_body, $body);
		#my $dir = dir("/home/da_bourq/Desktop/test");
		#my $filename = $dir -> file("$simple".'_'."$du".".txt");
		
		#open (my $fh, '>', $filename);
		#print $fh $more_body;
		#close $fh;


		#$ngram = getnGram($more_body);	

		#print "ORIGINAL:\n$body\n\nFIRSTPASS:\n$clean_body\n\nSECONDPASS\n$cleaner_body\n\nTHIRDPASS\n$more_body\n\n";
	
		

		#if ($pqn !~ /.*\..*/){
		#	print "pqn: ".$pqn."\n"."simple: ".$simple."\n"."we get: ".substr($sc, $pos, $len)."\n\n";
			
		#}
	}
	
	$final_body = join ' ', @all_body;
	my $final_original_body = join ' ', @all_original_body;
	#print $final_original_body;
	$ngram = getnGram($final_body);
	print $ngram;

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


#for regenerating the text to dump into nlp pipeline
elsif($config{processing} eq 'nlp' and $config{doc_type} eq 'stackoverflow') {

    my $get_du = $dbh_ref->prepare(qq[
                  select parentid, id, title, body, msg_date from                                                                                                                                                              
                  (select id as parentid, id, title, body, creationdate as msg_date from posts where id in (select id from posts where tags ~ E'lucene') --the parents                                                                
                  union select parentid, id, title, body, creationdate as msg_date from posts where parentid in (select id from posts where tags ~ E'lucene')) as r --the children                                                    
                  order by parentid, msg_date asc
                  ]);

    my $get_pos_len = $dbh_ref->prepare(qq{select pqn, simple, kind, pos, length(simple) as len from clt where trust = 0 and du = ?  order by pos});

    $get_du->execute or die "Can't get doc units from db ", $dbh_ref->errstr;


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
        while ( my($pqn, $simple, $kind, $pos, $len) = $get_pos_len->fetchrow_array) {
            #test - print " $old_end, $pos, $len --", substr($sc, $old_end, $pos-$old_end), "\n";
            my $current = substr($sc, $old_end, $pos-$old_end);
            print html->code_snips_to_html($current);
            $old_end = $pos+$len;
            #test - print " $old_end, $pos -- prxh_$kind\{$pqn\.$simple\} \n";
            print " $map_kind{$kind}$pqn\.$simple$end_kind ";
        }

        print html->code_snips_to_html(substr($sc, $old_end, length($sc)));
        print "<br><a href=\"http://stackoverflow.com/questions/$du\">Post: $du</a><br>\n";

    }
    $get_du->finish;
}
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

#
#For stackoverflow
elsif($config{doc_type} eq 'stackoverflow') {

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
	resolve->process($tid, $du, html->strip_html($content));

    }
    $get_du->finish;
}
#
#For recodoc -- legacy 
elsif($config{doc_type} eq 'recodoc') {

    my $get_du = $dbh_ref->prepare(q{select t.url, m.url, m.title, m.text_content from channel_message m, channel_supportthread t where m.sthread_id = t.id and t.channel_id = 2});
    #and m.url = '199145'}); #for stacktraces
    #m.url = '1150615'}); #test for generics # and m.url = '1116614'});
    $get_du->execute or die "Can't get doc units from db ", $dbh_ref->errstr;

    #Stack overflow
    while ( my($tid, $du, $title, $content) = $get_du ->fetchrow_array) {

        if(defined $title) {
            $content = $title . ' ' . $content;
        }
            #test - print " $old_end, $pos -- prxh_$kind\{$pqn\.$simple\} \n";


        print "\n\nprocessing du = $du\n";
	resolve->process($tid, $du, html->strip_html($content));

    }
    $get_du->finish;
}
#tutorial
elsif($config{doc_type} eq 'tutorial') {

    my $db_check_repo_ref = $dbh_ref->prepare(q{select tid from clt where tid = ? group by tid});
    resolve->process_dir($config{path}, \%config, $db_check_repo_ref);
    $db_check_repo_ref->finish;
}
else {
    print STDERR "Invalid doc_type ", $config{doc_type};
}

__END__
