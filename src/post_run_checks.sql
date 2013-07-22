\set ECHO all

--a very limited set of postrun checks, if you are going to modify this script ask me for the test cases

--du must be globally unique
--If you don't have a date or a post order you can use resolve_thread_freq.pl
select kind, trust, count(*) from clt group by kind, trust order by kind, count(*) desc;

--After a re-run check (need to create table ce and clt _old before re-run
select c.du, c.pqn, c.simple, c.kind, o.du, o.pqn, o.simple, o.kind from clt c full outer join clt_old o on (c.du = o.du and c.pqn = o.pqn and c.simple = o.simple and c.kind = o.kind) where c.du is null or o.du is null order by c.du, o.du;


