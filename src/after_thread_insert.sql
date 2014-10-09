vacuum clt_temp;
analyze clt_temp;

update clt set pqn = a.pqn, kind = a.kind, reason = a.reason, trust = 0 from clt_temp as a where clt.tid = a.tid and clt.simple = a.simple;

vacuum clt;
analyze clt;
