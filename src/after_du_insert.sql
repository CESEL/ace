vacuum clt_temp;
analyze clt_temp;

update clt set pqn = a.pqn, kind = a.kind, reason = a.reason, trust = 0 from clt_temp as a where clt.du = a.du and clt.simple = a.simple and clt.trust > 0 and clt.kind <> 'variable';

vacuum clt;
analyze clt;
