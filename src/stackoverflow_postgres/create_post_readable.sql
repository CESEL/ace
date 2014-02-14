\set ECHO all

drop table if exists posts;
create table posts (
	id int,
	post_type_id int,
	parent_id int,
	accepted_answer_id int,
	creation_date timestamp with time zone,
	score numeric,
	viewcount numeric,
	body text,
	owner_user_id int,
	last_editor_user_id int,
	last_editor_display_name text,
	last_edit_date timestamp with time zone,
	last_activity_date timestamp with time zone,
	community_owned_date timestamp with time zone,
	closed_date timestamp with time zone,
	title text,
	tags text,
	answer_count numeric,
	comment_count numeric,
	favorite_count numeric
);

