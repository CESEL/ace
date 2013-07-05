\set ECHO all

drop table if exists clt;
create table clt (
    tid text, -- the tread id (e.g., the question)
    du text, -- the document unit id (e.g., the answer)
    pqn text, -- the partial qualified name (i.e., the declaring type)
    simple text, -- the name of the code element
    kind text, -- annotation, method, type, enum, variable, field, annotation_package, package
    trust int, -- See README
    pos int, -- location in the text where the code element occurs
    snip boolean, --is it part of a code snippet?
    reason text --verbose trust/how a code element was resolved
);

--don't want any indexes, we're doing massive inserts
drop index if exists du_idx;
drop index if exists simple_idx;
drop index if exists tid_idx;

