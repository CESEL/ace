\set ECHO all

--alter table clt drop column context;
--alter table clt add column context integer default 1; --local
update clt set context = 0 where reason = 'naturally good'; --not ambig so doesn't need context
update clt set context = 2 where reason ~ 'thread'; --thread
update clt set context = 3 where reason ~ E'(two posts|most pop|= lower)'; --collection
update clt set context = 4 where reason is null; --never resolved

--no promises that this list is complete so run 
select reason, count(*) from clt group by reason order by reason;

--                     reason
----------------------------------------------------
----0 naturally good
----4 (null)
--1 stacktrace
--1 already defined in local context
--1 method chain
--3 type for var with most members or most pop
--2 already defined in thread context
--3 type: 3, but used in more than two posts
--1 defined class
--2 variable already defined in thread context
--3 lower(variable) = lower(class)
--1 member class defined: 7
--1 member class defined: 1
--1 annotation
--1 member class defined: 2
--1 member class defined, but meth already taken 3
--1 member class defined 7
--1 member class defined 3
--2 thread: member class defined: 2
--2 thread: member class defined: 7
--2 thread: member class defined 7
----(21 rows)
