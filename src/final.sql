\set ECHO all

--check with this query first: might want to create an exclude list based on project name etc (e.g., HttpClient)
--select simple, count(*) from clt where kind = 'type' and trust = 3 and simple in (select simple from clt where kind = 'type' and trust = 0 group by simple having count(*) > 1) group by simple order by count(*) desc;
--doing the above for trust = 7 would be living too close to the edge, see for yourself
--update clt set pqn = simple, reason = 'type: 3, but used in more than two posts', trust = 0 where kind = 'type' and trust = 3 and simple in (select simple from clt where kind = 'type' and trust = 0 group by simple having count(*) > 1) and simple !~ E'^(Hibernate)$';

--update clt set pqn = simple, reason = 'type: 3, but used in more than two posts', trust = 0 where kind = 'type' and trust = 3 and simple in (select simple from clt where kind = 'type' and trust = 0 group by simple having count(*) > 1) and simple !~ E'^(HttpClient)$';

--Hibernate|HttpClient ...

VACUUM clt;
ANALYZE clt;

--drop temp tables
--drop table if exists du_undef; 
--drop table if exists du_context;
--
--drop table if exists tid_undef; 
--drop table if exists tid_context;
