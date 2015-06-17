\set ECHO all

--pick a random group of posts that have at least 3 code elements
-- store it so we can run it more than once
--drop table if exits random_du;
create table random_du as (select du from docs_clt group by du having count(*) > 3 order by random() limit 100);

copy (
	select tid, c.du, pqn, simple as name, kind, pos
		from random_du l, clt c 
		where l.du = c.du 
		--trust > 0 are valid
		and trust = 0 
		--if it is a stackdump it's = 8
		and trust_original <> 8 
		--only want answers, questions are junky
		and tid <> c.du 
		--variables aren't code elements
		and kind <> 'variable' 
		--order by the post_id, and the position in the pos	
		order by c.du, pos
) To '/tmp/clt.csv' with CSV;

copy (
	select tid, c.du, pqn, simple as name, kind, pos
		from random_du l, docs_clt c 
		where l.du = c.du 
		--trust > 0 are valid
		and trust = 0 
		--if it is a stackdump it's = 8
		and trust_original <> 8 
		--only want answers, questions are junky
		and tid <> c.du 
		--variables aren't code elements
		and kind <> 'variable' 
		--order by the post_id, and the position in the pos	
		order by c.du, pos
) To '/tmp/docs_clt.csv' with CSV;


