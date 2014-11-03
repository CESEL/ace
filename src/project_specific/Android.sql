\set ECHO all

--check with this query first: might want to create an exclude list based on project name etc (e.g., HttpClient)
--Note: doing the above for trust = 7 would be living too close to the edge, so just trust = 3
select simple, count(*) from clt where kind = 'type' and trust = 3 and simple in (select simple from clt where kind = 'type' and trust = 0 group by simple having count(*) > 1) group by simple order by count(*) desc;

update clt set pqn = simple, reason = 'type: 3, but used in more than two posts', trust = 0 where kind = 'type' and trust = 3 and simple in (select simple from clt where kind = 'type' and trust = 0 group by simple having count(*) > 2);

