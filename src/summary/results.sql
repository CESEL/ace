\set ECHO all

select pqn, simple, '--' || word || '--', count(*), distance from summary where word !~ E'^\\s+$' and distance <= 2 group by pqn, simple, word, distance having count(*) > 2order by pqn, simple, count(*), distance desc;
