\set ECHO all

--unlogged is dangerous because if the system crashes all unlogged tables are truncated!
alter table clt rename to clt_unlogged;
create table clt as select * from clt_unlogged;

--drop temp tables
--drop table if exists du_undef; 
--drop table if exists du_context;
--
--drop table if exists tid_undef; 
--drop table if exists tid_context;


