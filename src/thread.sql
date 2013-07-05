\set ECHO all

--simple name already defined in tread context (duplicate simple name with multiple types?)
update clt set pqn = r.pqn, trust = 0, reason = 'already defined in thread context' from (select tid, simple, pqn, kind from clt where pqn <> '!undef!' and kind <> 'package' and trust = 0) as r where r.tid = clt.tid and r.kind = clt.kind and r.simple = clt.simple and clt.pqn = '!undef!';

drop table if exists tid_undef; 
create table tid_undef as select tid, simple, trust, date from clt where (kind = 'method' or kind = 'field') and trust > 1 group by tid, simple, trust, date;
create index tid_undef_tid_idx on tid_undef(tid);
create index tid_undef_simple_idx on tid_undef(simple);

drop table if exists tid_context;
create table tid_context as select tid, simple, trust, date from clt where kind = 'type' group by tid, simple, trust, date; 
create index tid_context_tid_idx on tid_context(tid);
create index tid_context_simple_idx on tid_context(simple);
