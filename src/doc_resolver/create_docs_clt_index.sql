\set ECHO all

--if you add an index make sure you delete it in create.sql
drop index if exists simple_docs_idx;
create index simple_docs_idx on docs_clt(simple, pqn);
drop index if exists tid_docs_idx;
create index tid_docs_idx on docs_clt(tid);
drop index if exists du_docs_idx; 
create index du_docs_idx on docs_clt(du);

ANALYZE docs_clt;


