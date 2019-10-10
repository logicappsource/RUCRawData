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

-- drop function test_variadic(VARIADIC w text[]);
create or replace function test_variadic(VARIADIC w text[])
returns table(questionid integer, title text, body text) as $$
declare
	w_elem text;
	t text := 'select questionid, title, body from questions, ';
	idx integer default 0;
	w_length int := array_length(w, 1);
begin
	foreach w_elem in array w
	loop
	idx := idx + 1;
	if idx = 1 then
		t := t || '(SELECT id FROM stack_wi WHERE word= ''' || w_elem || ''' ';
	end if;

	if idx > 1 and idx < w_length then
		t := t || 'intersect SELECT id FROM stack_wi WHERE word= ''' || w_elem || ''' ';
	end if;

	if idx = w_length then
		t := t || 'intersect SELECT id FROM stack_wi WHERE word= ''' || w_elem || ''') t where questions.questionid = t.id ';
	end if;

	end loop;
	return query execute t;
end $$
language 'plpgsql';

select * from test_variadic('missing', 'something', 'here', 'admit')
-- select * from test_variadic('here');

D4

drop function if exists best_match(VARIADIC w text[]);
create or replace function best_match(VARIADIC w text[])
returns table(questionid integer, rank bigint, body text) as $$
declare
	w_elem text;
	t text := 'SELECT q.questionid, sum(relevance) rank, body FROM questions q, ';
	idx integer default 0;
	w_length int := array_length(w, 1);
begin
	foreach w_elem in array w
	loop
	idx := idx + 1;
	if idx = 1 then
		t := t || '(SELECT distinct id, 1 relevance FROM stack_wi WHERE word = ''' || w_elem || ''' ';
	end if;

	if idx > 1 and idx < w_length then
		t := t || 'UNION ALL SELECT distinct id, 1 relevance FROM stack_wi WHERE word = ''' || w_elem || ''' ';
	end if;

	if idx = w_length then
		t := t || 'UNION ALL SELECT distinct id, 1 relevance FROM stack_wi WHERE word = ''' || w_elem || ''') t WHERE q.questionid=t.id GROUP BY q.questionid, body ORDER BY rank DESC; ';
	end if;

	end loop;
	return query execute t;
end $$
language 'plpgsql';

select * from best_match('of', 'and')

D5
DROP TABLE IF EXISTS weighted_index;
CREATE TABLE weighted_index(
id int4, word text, term_count numeric, total_term_count numeric, documents_containing_term numeric, tf numeric, idf numeric, relevance_of_doc_to_term numeric);

INSERT INTO weighted_index
select stack_wi.id, stack_wi.word, count(*) term_count, total_term_count, documents_containing_term
from stack_wi
inner join (select id, count(*) total_term_count from stack_wi group by stack_wi.id) t on t.id = stack_wi.id
inner join (select word, count(*) documents_containing_term from stack_wi group by word ) t2 on t2.word = stack_wi.word
group by stack_wi.id, stack_wi.word, total_term_count, documents_containing_term;


D6
-- select * from weighted_index where id = 19;
-- select count(id) from weighted_index;

drop function if exists relevanceOfDocumentToTerm();
create or replace function relevanceOfDocumentToTerm(questionid integer, term text)
returns numeric as $$
declare
	termFrequency numeric;
	inverseDocumentFrequency numeric;
	relevanceOfDocToTerm numeric;
	record record;
begin
for record in select distinct * from weighted_index where id = questionid and word = term loop

	 termFrequency = log(1::numeric + (record.term_count::numeric / record.total_term_count::numeric));
	 inverseDocumentFrequency = 1 / termFrequency;
	 relevanceOfDocToTerm = termFrequency * inverseDocumentFrequency;
end loop;

	return relevanceOfDocToTerm;
end; $$
language 'plpgsql';

-- select * from relevanceOfDocumentToTerm(19, 'acos');
---------------------
-- select * from weighted_index where id = 28905111;
drop function if exists insertRelevance();
create or replace function insertRelevance()
returns void as $$
declare
	relevanceOfDocToTerm numeric;
	record record;
begin
for record in select distinct * from weighted_index limit 10 loop
	relevanceOfDocToTerm = (select * from relevanceOfDocumentToTerm(record.id, record.word));
  update weighted_index set relevance_of_doc_to_term=relevanceOfDocToTerm where id = record.id and word = record.word;
end loop;
end; $$
language 'plpgsql';

-- select * from insertRelevance();

drop function if exists best_match(VARIADIC w text[]);
create or replace function best_match(VARIADIC w text[])
returns table(questionid integer, rank bigint, body text) as $$
declare
	w_elem text;
	t text := 'SELECT q.questionid, sum(relevance_of_doc_to_term) rank, body FROM questions q, ';
	idx integer default 0;
	w_length int := array_length(w, 1);
begin
	foreach w_elem in array w
	loop
	idx := idx + 1;
	if idx = 1 then
		t := t || '(SELECT distinct id, relevance_of_doc_to_term FROM stack_wi WHERE word = ''' || w_elem || ''' ';
	end if;

	if idx > 1 and idx < w_length then
		t := t || 'UNION ALL SELECT distinct id, relevance_of_doc_to_term FROM stack_wi WHERE word = ''' || w_elem || ''' ';
	end if;

	if idx = w_length then
		t := t || 'UNION ALL SELECT distinct id, relevance_of_doc_to_term FROM stack_wi WHERE word = ''' || w_elem || ''') t WHERE q.questionid=t.id GROUP BY q.questionid, body ORDER BY rank DESC; ';
	end if;

	end loop;
	return query execute t;
end $$
language 'plpgsql';
