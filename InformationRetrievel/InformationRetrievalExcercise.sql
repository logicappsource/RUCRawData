--/Question 1
--/Consider the words-table. This table provides an elaborate inverted index on the posts and the comments table.

a)
--/ what post word millisecond appear
SELECT id
FROM words
WHERE word = 'millisecond'
AND
tablename = 'posts'
--/ what post word instrumentation appear
SELECT id
FROM words
WHERE word = 'instrumentation'
AND
tablename = 'posts'

--/ what post instrumentation appear
SELECT title
FROM posts_universal p
WHERE p.id = 2862556

select * from words
where word = 'millisecond'and
tablename = 'posts'

b)
select * from (select id from words
where word = 'millisecond'and
tablename = 'posts') milPosts
intersect
(select id from words
where word = 'instrumentation'and
tablename = 'posts')

--/Question 2


--/Question 3
--/a)
--/ Creates a new table from words table mapping the id and word with a regular expression.
--/ Preparing the data makes it more efficent to query the new inverted index.
--/ This reults in reducing and filtering the duplicated words into a single entry

--/b)
--/ Filtering stop words that are useless

--c)
--/ Apply a VARIADIC function would return the count of the occurence of each words

--d)
--/


--/ Question 4
--/ a)
--/ title & word

--/ Question 5
CREATE OR REPLACE FUNCTION test_variadic(VARIADIC w text[])
RETURNS text AS $$
DECLARE
incrementer int DEFAULT 0;
w_elem text;
t text = 'SELECT id, sum(relevance) rank, body FROM posts_universal,';
BEGIN
FOREACH w_elem IN ARRAY w
LOOP
if incrementer=0 THEN
		t := || '(SELECT DISTINCT id, 1 relevance FROM wi WHERE word=w_elem ';
end if;
if incrementer > 0 AND incrementer < 3 THEN
		t := || UNION ALL SELECT DISTINCT id, 1 relevance FROM wi WHERE word=w_elem;
end if;
if incrementer = 3 THEN 
		t := || UNION ALL SELECT DISTINCT id, 1 relevance FROM wi WHERE word=w_elem) WHERE wi.id=id GROUP by id, body ORDER by rank DESC;
end if;

t := t || w_elem || ' ' ||
(select count(id) from wi where wi.word = w_elem) || ' ';

incrementer := incrementer + 1;
END LOOP;
RETURN t;
END $$
LANGUAGE 'plpgsql';
SELECT test_variadic('regions', 'blocks', 'likes', 'chocolate') AS result;
