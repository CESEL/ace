\set ECHO all

drop table if exists clt_temp;
create unlogged table clt_temp (
    du text, -- the document unit id (e.g., the answer)
    pqn text, -- the partial qualified name (i.e., the declaring type)
    simple text, -- the name of the code element
    kind text, -- annotation, method, type, enum, variable, field, annotation_package, package
    trust int, -- See README
    reason text, --verbose trust/how a code element was resolved
    primary key(du, simple)
);


