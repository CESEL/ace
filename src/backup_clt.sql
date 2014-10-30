\set ECHO all

--unlogged is dangerous because if the system crashes all unlogged tables are truncated!
drop table if exists clt_logged;
create table clt_logged as select * from clt;


