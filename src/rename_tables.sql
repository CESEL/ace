\set ECHO all

--drop temp tables
drop table if exists du_undef; 
drop table if exists du_context;
drop table if exists tid_undef; 
drop table if exists tid_context;

drop table if exists clt_backup;

--rename tables
alter table clt rename to clt_android;
alter table ce rename to ce_android;
alter table du_undef rename to du_undef_android;

--rename indexes
alter index simple_idx to simple_idx_android;
alter index tid_idx to tid_idx_android;
alter index du_idx to du_idx_android;
alter index ce_simple_idx to ce_simple_idx_android;

