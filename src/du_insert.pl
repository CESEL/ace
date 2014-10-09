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

--the kind will be undefined, so use the kind from the possibles
select i.du, c.simple as type, c.trust as type_trust, i.simple, i.trust, p.kind, abs(i.pos - c.pos) as abs_pos from 

--get undefined methods and fields
du_undef as i,

--get available types in context
du_context as c,

--get possible valid types
ce as p

--join: context = du 
where c.du = i.du and 
--type is valid and available, 
c.simple = p.pqn and p.simple = i.simple and 
--we are only looking at posible valid members
(p.kind = 'method' or p.kind = 'field') and
--either the member or the class was undefined 
(i.trust  > 0 or c.trust > 0) 

--in case of a tie, the closer in the doc, the better.
order by du, i.simple, abs(i.pos - c.pos)
});
    
$get_ref->execute or die $dbh_ref->errstr;

#Check to make sure the class by itself isn't already defined
my $check = $dbh_ref->prepare(q{select du, simple from clt_temp where du = ? and simple = ?});
my $insert = $dbh_ref->prepare(q{insert into clt_temp (pqn, kind, reason, trust, du, simple) values (?,?,?,0,?,?)}); 

my @prev;
my $is_new = 0;
while ( my($du, $type, $type_trust, $simple, $simple_trust, $kind, $abs_pos) = $get_ref->fetchrow_array) {

    # is the type already been added to clt_temp?
    $check->execute($du, $type) or die $dbh_ref->errstr;
    $is_new = $check->rows;

    #print "$du, $type, $type_trust, $simple, $simple_trust, $abs_pos\n\n";

    if (!defined $prev[0] or $prev[0] ne $du or $prev[1] ne $simple) {
        #update method
        $insert->execute($type, $kind, "member class defined: $simple_trust", $du, $simple) or die $dbh_ref->errstr;

        #update class as it's being used
        if ($is_new == 0 and $type_trust > 0) {
            $insert->execute($type, 'type', 'local context', $du, $type) or die $dbh_ref->errstr;
        }

    }
    elsif ($is_new == 0 and $type_trust > 0) {
        $insert->execute($type, 'type', 'local context', $du, $type) or die $dbh_ref->errstr;
    }

    @prev = ($du, $simple);

}

$dbh_ref->commit;

$check->finish;
$insert->finish;
$get_ref->finish;
$dbh_ref->disconnect;

__END__

No new classes or methods will be discovered in this process!
TODO: Deal with variables that can be defined now!

_RANDOM OLD STUFF_

--undefined and more than one conflicting class for method at trust 2
select i.du, i.simple, count(*) from (select du, simple from clt where kind = 'method' and trust = 2 group by du, simple) as i, (select pqn, simple, count(*) as cnt from clt where kind = 'method' and trust = 0 group by pqn, simple) as p, (select du, simple from clt where kind = 'type' and pqn = '!undef!' group by du, simple) as c where c.du = i.du and c.simple = p.pqn and p.simple = i.simple group by i.du, i.simple having count(*) > 1 order by du, count(*) desc;


--normal hash -> no bad words
--special hash -> all words in the thread???
--bad words, ie ones that occur in a ridiculously large set
select simple, count(*) as cnt, cast(count(distinct(du)) as numeric)/1046 as du from clt where trust = 7 group by simple having cast(count(distinct(du)) as numeric)/1046 > .1 order by du desc;
