\set ECHO all

--alter table to include date
--alter table clt add column date timestamp with time zone;

--one of these!

--Recodoc
--update clt set date = msg_date from channel_message m where cast(du as int) = m.id;


--updates take too long
alter table clt rename to clt_delme;

--One of these will fail, but we keep both so as not to have to modify them on each run

--stackoverflow
create unlogged table clt as select c.*, p.creationdate as date from clt_delme c, posts p where cast(du as int) = p.id

--For email
create unlogged table clt as select c.*, e.date as date from clt_delme c, email e where c.du = e.msg_id;

--drop table clt_delme;




