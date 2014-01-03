\set ECHO all

--a few this and super will slip through when there is no defined class to overwrite
delete from clt where (pqn = 'super' or pqn = 'this') and kind = 'variable';
update clt set pqn = '!undef!', trust = 5 where kind = 'field' and (pqn = 'super' or pqn = 'this');

--get all packages that are valid, then update for those that have the same name
update clt set simple = '.*', trust = 0 from (select pqn, count(distinct(simple)) from clt where kind = 'package' and simple <> '!undef!' group by pqn) as r where clt.kind = 'package' and clt.simple = '!undef!' and r.pqn = clt.pqn;
--remove the rest, they're almost certainly urls
delete from clt where trust = 9;

--not a bad idea if you are experimenting
--drop table if exists clt_backup;
--create table clt_backup as select * from clt;

--in hibernate variable names in sql end in _
--delete from clt where pqn ~ E'_$' or simple  ~ E'_$';

--want to know where it came from
--alter table clt add column trust_original integer;
update clt set trust_original = trust where trust_original is null;
--alter table clt add column kind_original text;
update clt set kind_original = kind where kind_original is null;

--all SQL updates in here have the power to add new ce to the gold standard

update clt set kind = 'type' where kind = 'constructor';

update clt set kind = 'type' where kind = 'exception';

update clt set reason = 'naturally good' where trust = 0;

update clt set trust = 0, reason = 'method chain' where trust = 4;

update clt set trust = 0, reason = 'defined class' where trust = 6;

update clt set trust = 0, reason = 'stacktrace' where trust = 8;

--variable resolve at thread level, includes any associated methods
update clt set pqn = r.pqn, trust = 0, reason = 'variable already defined in thread context' from (select tid, simple, pqn from clt where kind = 'variable' and trust = 0) as r where r.tid = clt.tid and clt.pqn = r.simple and clt.trust = 1;


