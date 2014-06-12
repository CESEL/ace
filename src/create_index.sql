\set ECHO all

VACUUM clt;

--if you add an index make sure you delete it in create.sql
drop index if exists simple_idx;
create index simple_idx on clt(simple);
drop index if exists tid_idx;
create index tid_idx on clt(tid);
drop index if exists du_idx; 
create index du_idx on clt(du);

ANALYZE clt;


