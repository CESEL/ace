\set ECHO all

--alter table to include date
alter table clt add column date timestamp with time zone;

--one of these!
--update clt set date = msg_date from channel_message m where cast(du as int) = m.id;
--update clt set date = to_timestamp(p.creationdate) from posts p where cast(du as int) = p.id; -- get rid of timestamp conversion
update clt set date = p.creationdate from posts p where cast(du as int) = p.id;
--update clt set date = msg_date from limited_posts p where cast(du as int) = p.id;

vacuum clt;
analyze clt;



