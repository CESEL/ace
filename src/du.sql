\set ECHO all

--simple name already defined in local context (duplicate simple name with multiple types?)
update clt set pqn = r.pqn, trust = 0, reason = 'already defined in local context' from (select du, simple, pqn, kind from clt where pqn <> '!undef!' and kind <> 'package' and trust = 0) as r where r.du = clt.du and r.kind = clt.kind and r.simple = clt.simple and clt.pqn = '!undef!';


--create the tables
drop table if exists du_undef; 
create table du_undef as select du, simple, trust, pos from clt where (kind = 'method' or kind = 'field') and trust > 0 group by du, simple, trust, pos;
create index du_undef_du_idx on du_undef(du);
create index du_undef_simple_idx on du_undef(simple);

drop table if exists du_context;
create table du_context as select du, simple, trust, pos from clt where kind = 'type' group by du, simple, trust, pos;

create index du_context_du_idx on du_context(du);
create index du_context_simple_idx on du_context(simple);


