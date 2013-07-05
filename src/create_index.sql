\set ECHO all

update clt set trust_original = trust, kind_original = kind where trust = 7;

VACUUM clt;

--if you add an index make sure you delete it in create.sql
create index simple_idx on clt(simple);
create index tid_idx on clt(tid);

ANALYZE clt;


