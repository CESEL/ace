\set ECHO all

drop table if exists posts;
create table posts (
	id int,
	posttypeid int,
	parentid int,
	acceptedanswerid int,
	creationdate timestamp with time zone,
	score numeric,
	viewcount numeric,
	body text,
	owneruserid int,
	lasteditoruserid int,
	lasteditordisplayname text,
	lasteditdate timestamp with time zone,
	lastactivitydate timestamp with time zone,
	communityowneddate timestamp with time zone,
	closeddate timestamp with time zone,
	title text,
	tags text,
	answercount numeric,
	commentcount numeric,
	favoritecount numeric
);

