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
a) If given  word and a specific pos the corresponding lemma should be the same.
We can verify this assumption by running the following query:
<start query>
select word, pos, lemma, count(*) as matchCount from words
where
word = 'looking'
group by word, pos, lemma
<end query>
If we dont get multiple tuples with a different lemma then the assumption is correct.

b) point a expressed as functional dependency is
word -> pos, lemma
A normalization would look like the following:
Before normalization we have a table(posts_universal) containing word, pos, lemma attributes.
After normalization we have 2 tables, first table(posts_universal) contains attribute word but we remove pos and leemma attributes.
Second table(word_pos_lemma) is comprised of attributes word, pos, lemma(word determines pos and lemma)

c) candidate keys results of table word_pos_lemma are:
candidate keys: { word }
not candidate keys, but super keys: { word, pos }, {word, lemma}, {word, pos, lemma} (Candidate key is a super key from which you cannot remove any fields)

--/Question 3
a)
Creates a new table from words table mapping the id and word with a regular expression.
Preparing the data makes it more efficent to query the new inverted index.


The result conforms to the description on the slide because in the sql query we only consider title and body in posts,
we ignore linguisting knowledge and positions, we ignore case(lowercase function) and the result is a new table wi which contains postid and word

b)
extra: Filtering stopwords that are useless, we can remove duplicates as well by using distinct function.
This approach coul exclude too much if we also consider ranking of words.

c)
Apply a VARIADIC function would return the count of the occurence of each words

d)
Before creating the wi table we would have to join the stopwords table and then check for the stopword and not add it to the wi table.
advantages for doing this is in some cases that the ranking of documents will be more accurate, a disadvantage would be in the case of 'flight to paris'
that if we remove the term 'to' then the query will return ambigous results, like fligts 'from' paris.


Question 4
a)
the values can be any unsigned integer bigger than 0
b)
It leads to the desired raning because we use 'union all'(using only union would override duplicates).  Union all used with the 3 words we want will.
The ranking is determined by the sum of the relevance - relevance is increased by 1 every time the post contains one of the terms.
The best match criteria is based upon containing one or more of the giving keywords. Ranked by DESC order, the number of keywords matched by the post.
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
