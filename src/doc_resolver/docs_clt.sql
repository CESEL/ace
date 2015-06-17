\set ECHO all 

drop table if exists docs_clt;

create table docs_clt as select clt.* from clt, (select class from docs group by class) as d where trust = 0 and simple = class and kind = 'type'; 

insert into docs_clt select clt.* from clt, docs where trust = 0 and simple = method and pqn = class and kind = 'method';

--if you add an index make sure you delete it in create.sql
drop index if exists simple_docs_idx;
create index simple_docs_idx on docs_clt(simple, pqn);
drop index if exists tid_docs_idx;
create index tid_docs_idx on docs_clt(tid);
drop index if exists du_docs_idx; 
create index du_docs_idx on docs_clt(du);

ANALYZE docs_clt;


