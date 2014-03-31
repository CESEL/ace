\set ECHO all

VACUUM clt;

--if you add an index make sure you delete it in create.sql
create index simple_idx on clt(simple);
create index tid_idx on clt(tid);
create index du_idx on clt(du);

ANALYZE clt;


