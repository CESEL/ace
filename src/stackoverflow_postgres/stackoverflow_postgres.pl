#!/usr/bin/perl -w

use warnings;
use strict;

use DBI;
use Config::General;

my $config_path = shift @ARGV;

if (!defined $config_path) {
	$config_path = 'config';
}
die "Config file \'$config_path\' does not exist"
	unless (-e $config_path);

my %config =  Config::General::ParseConfig($config_path);

my $dbh_ref = DBI->connect("dbi:Pg:database=$config{db_name}", '', '', {AutoCommit => 0});

my $insert = $dbh_ref->prepare(q{insert into posts values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)});

my $cnt = 0;
while (my $line = <>) {

	my %fields;
	while (not $line =~ m/\G\z/gcs) {
		if($line =~ /\G\s(\w+)=\"(.*?)\"/gcxms) {
			#print "$1 = $2\n";
			$fields{$1} = $2;
		}
		elsif ($line =~ m/\G( . )/xgcs) {}; #{print "ILLEGAL CHAR: $1\n"};
	}

	if(defined $fields{Id}) { 
		$insert->execute($fields{Id},
			$fields{PostTypeId}, $fields{ParentId}, $fields{AcceptedAnserId},
			$fields{CreationDate}, $fields{Score}, $fields{ViewCount}, $fields{Body},
			$fields{OwnerUserId}, $fields{LastEditorUserId},
			$fields{LastEditorDisplayName}, $fields{LastEditDate},
			$fields{LastActivityDate}, $fields{CommunityOwnedDate}, $fields{ClosedDate},
			$fields{Title}, $fields{Tags}, $fields{AnswerCount}, $fields{CommentCount},
			$fields{FavoriteCount}); 
		$cnt ++;
		
	}
	if ($cnt == 10000) {
			$dbh_ref->commit;
			$cnt = 0;
	}
}


$dbh_ref->commit;
$insert->finish;
$dbh_ref->disconnect;

__END__

