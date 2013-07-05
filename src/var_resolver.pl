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
select du, r.pqn, unknown from 

--get the unknown variables and their fields or methods for the du
(select du, pqn as unknown, simple from clt where kind <> 'variable' and trust = 1 group by du, pqn, simple) as v, 

--KLUDGE: doesn't consider which classes are present :-(, too early to know noncompounds ...

--get the good variables and how popular they are 
(select pqn, simple, count(*) as pop from clt where kind = 'variable' and trust = 0 group by pqn, simple) as r, 

--get the good methods and fields and their associated types
(select pqn, simple from clt where (kind = 'method' or kind = 'field') and trust = 0 group by pqn, simple) as m

--good variable = unknown var, method exists on variable, good variable has the method in a du
where r.simple = unknown and m.pqn = r.pqn and m.simple = v.simple 

group by du, r.pqn, unknown 

--most covered methods in du, then by popularity
order by du, unknown, count(*) desc, sum(pop) desc;
});
    
$get_ref->execute or die $dbh_ref->errstr;

my $update = $dbh_ref->prepare(q{update clt set pqn = ?, reason = ?, trust = 0 where du = ? and pqn = ?});

my @prev;
while ( my($du, $pqn, $unknown) = $get_ref->fetchrow_array) {


    #print "$du, $type, $type_trust, $simple, $simple_trust, $abs_pos\n\n";

    #just take the max cnt, pop: the rest are garbage
    if (!defined $prev[0] or $prev[0] ne $du or $prev[1] ne $unknown) {
        #update var's and dependents 
        $update->execute($pqn, "type for var with most members or most pop", $du, $unknown);
    }

    @prev = ($du, $unknown);

}

$dbh_ref->commit;

$update->finish;
$get_ref->finish;
$dbh_ref->disconnect;

__END__

For undefined variables that have methods or fields, what is the most commonly declared variable type that has the same fields and methods in the entire collection of documents.
