#!/usr/bin/perl -w

use warnings;
use strict;

use DBI;
use Cwd;

use Config::General;
my $config_path = shift @ARGV;
if (!defined $config_path) {
	$config_path = 'config';
}
die "Config file \'$config_path\' does not exist"
	unless (-e $config_path);
my %config =  Config::General::ParseConfig($config_path);

my $dbh_ref = DBI->connect("dbi:Pg:database=$config{db_name}", '', '', {AutoCommit => 0});

my $get_ref = $dbh_ref->prepare(q{

select i.tid, c.simple as type, c.trust as type_trust, i.simple, i.trust, p.kind, abs(extract(epoch from i.date) - extract(epoch from c.date)) as abs_date, p.df from

--get undefined methods and fields
tid_undef as i,

--get available types in context
tid_context as c,

--get possible valid types
ce as p

--join: context = tid
where c.tid = i.tid and
--type is valid and available,
c.simple = p.pqn and p.simple = i.simple and
--we are only looking at posible valid members
(p.kind = 'method' or p.kind = 'field') and
--either the member or the class was undefined
(i.trust  > 0 or c.trust > 0)

--in case of a tie, the closer in date the better, still tied, we'll take the one that occurs in the most documents
order by tid, i.simple, abs_date asc, p.df desc

});

    
$get_ref->execute or die $dbh_ref->errstr;

#Check to make sure the class by itself isn't already defined
my $check = $dbh_ref->prepare(q{select tid, simple from clt_temp where tid = ? and simple = ?});
my $insert = $dbh_ref->prepare(q{insert into clt_temp (pqn, kind, reason, trust, tid, simple) values (?,?,?,0,?,?)});

my @prev;
my $is_new = 0;
while ( my($tid, $type, $type_trust, $simple, $simple_trust, $kind) = $get_ref->fetchrow_array) {


#    print "$tid, $type, $type_trust, $simple, $simple_trust\n\n";

    # is the type already been added to clt_temp?
    $check->execute($tid, $type);
    $is_new = $check->rows;

    if (!defined $prev[0] or $prev[0] ne $tid or $prev[1] ne $simple) {
        #update method
        $insert->execute($type, $kind, "thread: member class defined: $simple_trust", $tid, $simple);

        #update class as it's being used
        if ($is_new == 0 and $type_trust > 0) {
            $insert->execute($type, 'type',  "thread context", $tid, $type);
        }

    }
    elsif ($is_new == 0 and $type_trust > 0) {
        $insert->execute($type, 'type',  "thread context", $tid, $type);

    }

    @prev = ($tid, $simple);

}

$dbh_ref->commit or warn $dbh_ref->errstr;

$check->finish;
$insert->finish;
$get_ref->finish;
$dbh_ref->disconnect;

__END__
$dbh_ref = DBI->connect("dbi:Pg:database=$config{db_name}", '', '', {AutoCommit => 1});
$dbh_ref->do(q{vacuum clt_temp});
$dbh_ref->do(q{analyze clt_temp});
$dbh_ref->disconnect;

$dbh_ref = DBI->connect("dbi:Pg:database=$config{db_name}", '', '', {AutoCommit => 0});
#update clt
$dbh_ref->do(q{update clt set pqn = a.pqn, kind = a.kind, reason = a.reason, trust = 0 from clt_temp as a where clt.tid = a.tid and clt.simple = a.simple;});
$dbh_ref->commit;
$dbh_ref->disconnect;

$dbh_ref = DBI->connect("dbi:Pg:database=$config{db_name}", '', '', {AutoCommit => 1});
$dbh_ref->do(q{vacuum clt});
$dbh_ref->do(q{analyze clt});
$dbh_ref->disconnect;


