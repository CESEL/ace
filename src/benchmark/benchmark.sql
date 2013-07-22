\set ECHO all

--update with new
drop table if exists benchmark;
create table benchmark (
    essential text,
    valid text, 
    simple text,
    pqn text,
    cnt int,
    kind text,
    min_pos int,
    trust int,
    tid text,
    du text,
    rationale text
);

copy benchmark from '/tmp/bench_good.csv' csv header;
update benchmark set valid = 'tn' where pqn = '!undef!' and valid is null;
update benchmark set essential = '1' where essential = 't'; 
update benchmark set essential = '0' where essential is null;
update benchmark set valid = 'tp' where valid is null; 
--this is an oops incase we didn't update trust manually for a fn
update benchmark set valid = 'fn' where trust = '-1' and valid <> 'fn';

--get next X -- include du <> tid if you want to exclude questions
-- from clt where du <> tid 
copy(select simple, pqn, count(*) as cnt, kind, min(pos) as min_pos, trust, tid, du from clt where trust <> 7 and du in (select du from (select du from clt group by du except select du from benchmark group by du) as r order by random() limit 200) group by tid, du, pqn, simple, kind, trust order by du, min(pos)) to '/tmp/bench.csv' with csv header;

--get a copy of the current benchmark as csv
copy(select * from benchmark order by du, min_pos) to '/tmp/bench_copy.csv' with csv header;

--another check
--select b.du, b.simple, b.pqn, b.kind, c.du, c.simple, c.pqn, c.kind from benchmark b full outer join (select du, simple, pqn, kind from clt where trust <> 7 and du in (select du from benchmark group by du) group by du, simple, pqn, kind) c on (c.du = b.du and c.simple = b.simple and c.pqn = b.pqn and c.kind = b.kind) where c.du is null or b.du is null order by b.du, c.du
;
--copy(select c.simple, c.pqn, count(*) as cnt, c.kind, min(c.pos) as min_pos, c.trust, c.tid, c.du from (select * from clt c where du in (select du from benchmark group by du)) as c left outer join benchmark b on (c.du = b.du and c.simple = b.simple and c.pqn = b.pqn and c.kind = b.kind) where b.du is null and c.trust <> 7 group by c.tid, c.du, c.pqn, c.simple, c.kind, c.trust order by c.du, min(c.pos)) to '/tmp/bench_bad.csv' with csv header;


