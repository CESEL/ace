\set ECHO all

drop table if exists summary;
create table summary (
	du text,
	pos numeric,
	pqn text,
	simple text,
	word text,
	distance numeric,
	ngram numeric

)
