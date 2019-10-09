D1
-- search based on keywords and return question ids
DROP FUNCTION if exists simpleSearchKeyword(userid int, S text);
CREATE OR REPLACE FUNCTION simpleSearchKeyword(userid int, S text)
returns int[] as $$
declare questionIdsArray int[] DEFAULT '{}';
declare t_row record;
declare storeSearchVar text;
begin
 for t_row in SELECT questionid FROM questions 	WHERE
	title ~* S or body ~* S loop
	questionIdsArray := questionIdsArray || t_row.questionid;
 end loop;

select storeSearch(userid, S) into storeSearchVar;
return questionIdsArray;
end;
$$
LANGUAGE plpgsql;
-- select simpleSearchKeyword(2, 'keyword');


-- storing searches initiated by user
drop function if exists storeSearch(userid int, querytext text);
create  or replace function storeSearch(userid int, querytext text)
	returns text as $$
	declare storedsearch text;
	begin
		INSERT INTO search_history (searchdate, userid, querytext)
		VALUES (NOW(), userid, querytext);
		storedsearch =  NOW() || ',' || userid || ',' || querytext;
		return storedsearch;
	end;
	$$
language plpgsql;
-- select storeSearch(1, 'keyword')

-- add a marking
drop function if exists addMarking(userid int, questionid int)
create  or replace function addMarking(userid int, questionid int)
	returns void as $$
	begin
		INSERT INTO markings (userid, questionid)
		VALUES (userid, questionid);
	end;
	$$
language plpgsql;
select addMarking(1, 1)

-- add an annotation
drop function if exists addAnnotation(userid int, questionid int, body text)
create  or replace function addAnnotation(userid int, questionid int, body text)
	returns void as $$
	begin
		INSERT INTO annotations (userid, questionid, body)
		VALUES (userid, questionid, body);
	end;
	$$
language plpgsql;
select addAnnotation(1, 1, 'hello there')

D2
--/ We established a new inverted index from the post table where we insert all distinct
--  words to lowercase from ‘title’ & ‘posts’ into the stack_wi table. Only a word and reference to that id is stored as an inverted index.
create table stack_wi as
select id, lower(word) word from words
where word ~* '^[a-z][a-z0-9_]+$'
and tablename = 'posts' and (what='title' or what='body')
group by id,word;


D3
