\set ECHO all

drop table if exists clt;
create unlogged table clt (
    tid text, -- the tread id (e.g., the question)
    du text, -- the document unit id (e.g., the answer)
    pqn text, -- the partial qualified name (i.e., the declaring type)
    simple text, -- the name of the code element
    kind text, -- annotation, method, type, enum, variable, field, annotation_package, package
    trust int, -- See README
    pos int, -- location in the text where the code element occurs
    snip boolean, --is it part of a code snippet?
    reason text, --verbose trust/how a code element was resolved
    trust_original integer, --originally how trustworthy the CE is (see README for values)
    kind_original text, -- we turn constructors into types, this is the original kind value
    context integer default 1, --groupings of reasons see context.sql
);


