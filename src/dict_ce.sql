\set ECHO all

--lowercase var = lowercase class -> update pqn for variable and for methods/fields
update clt set pqn = t.pqn, trust = 0, reason = 'lower(variable) = lower(class)' from (select du, simple from clt where kind = 'variable' and trust = 1) v, (select pqn from clt where (kind = 'method' or kind = 'field') and trust = 0 group by pqn) t where lower(t.pqn) = lower(v.simple) and clt.pqn = v.simple and (kind = 'variable' or kind = 'method' or kind = 'field');

--time to create the dictionary of CEs
drop table if exists ce;
create table ce (
    pqn text,
    simple text,
    kind text,
    df numeric, -- document frequency
    ef numeric, -- ecapsulated frequency (thread)
--    valid numeric default 1,
    primary key(pqn, simple, kind)
);

drop index ce_simple_idx;
create index ce_simple_idx on ce(simple);

--CE has to occur in > 1 thread, have trust < 2 (TODO, why)
--the length of the name must also be > 2 chars
--could change the having clause to df or ef > ?
insert into ce select pqn, simple, kind, count(distinct(du)) as df, count(distinct(tid)) as ef from clt where trust <= 1 and length(simple) > 2 and length(pqn) > 2 group by pqn, simple, kind having count(distinct(tid)) > 1;

ANALYZE ce;

create index du_idx on clt(du);


