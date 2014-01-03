\set ECHO all

--don't want any indexes, we're doing massive inserts
drop index if exists du_idx;
drop index if exists simple_idx;
drop index if exists tid_idx;

