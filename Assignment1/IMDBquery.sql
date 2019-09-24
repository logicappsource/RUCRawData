
(a)
select title, production_year from movie where title like 'Pirates of the Caribbean%'  and kind='movie'
  ----------------------------------------------------
(b)
select count(*) from movie where production_year = 2004 and kind = 'movie'
  ----------------------------------------------------
(c)
select movie.title from movie
join casting on movie."id" = casting.movie_id
join person on casting.person_id = person."id"
where person.name = 'Mikkelsen, Mads'
and movie.kind = 'video game'
  ----------------------------------------------------
(d)
select distinct casting.role_type from person
join casting on person."id" = casting.person_id
where person."name" = 'Bacon, Kevin'
  ----------------------------------------------------
(e)
SELECT COUNT
( role_type ),
role_type
FROM
casting
GROUP BY
        role_type
ORDER BY
        COUNT ( role_type ) DESC
  ----------------------------------------------------
(f)
select title from movie
join casting on casting.movie_id = movie."id"
join person on casting.person_id = person."id"
where person.name = 'Scott, Ridley'
and casting.role_type = 'director'
and movie.production_year in (2004, 2006, 2008, 2010)
  ----------------------------------------------------
(g)
select max(num) from
(select movie_id, count(movie_id) as num from casting
where role_type = 'actor'
group by movie_id) as T
  ----------------------------------------------------
(h) we havent managed to get the correct result
--/gives correct answer
--/would be better to find kevin bacons person.id
SELECT COUNT(DISTINCT person) FROM
(SELECT DISTINCT movie.id AS movid
    FROM movie
    INNER JOIN casting ON movie.id=casting.movie_id
    INNER JOIN person ON casting.person_id=person.id
    WHERE person.name='Bacon, Kevin' AND casting.role_type LIKE 'actor') bacon
INNER JOIN casting ON bacon.movid=casting.movie_id
INNER JOIN person ON casting.person_id=person.id
WHERE casting.role_type LIKE 'actor' AND person.name!='Bacon, Kevin';
mr pandele

  ----------------------------------------------------
(i)
select title from movie_keyword
join movie on movie."id" = movie_keyword.movie_id
join keyword on keyword."id" = movie_keyword.keyword_id
where keyword = 'elephant-fears-mouse'
----------------------------------------------------
(j)
select movie.title from movie_keyword
join movie on movie."id" = movie_keyword.movie_id
join keyword on keyword."id" = movie_keyword.keyword_id
where keyword = 'elephant-fears-mouse'
intersect
select movie.title from movie_keyword
join movie on movie."id" = movie_keyword.movie_id
join keyword on keyword."id" = movie_keyword.keyword_id
where keyword = 'dancing'
----------------------------------------------------
(k)
select title, production_year from movie
join movie_company on movie."id" = movie_company.movie_id
join company on movie_company.company_id = company."id"
where company.name = 'Paramount' and production_year>2004 and country_code='[se]' ORDER BY title
----------------------------------------------------
(l)
SELECT title
FROM movie
JOIN casting on movie."id" = casting.movie_id
JOIN role on casting.role_id = role."id"
WHERE role.name = 'The Singing Kid';
----------------------------------------------------
(m)
SELECT person.name, movie.title
FROM person
JOIN casting on person."id" = casting.person_id
JOIN role on casting.role_id = role."id"
JOIN movie on casting.movie_id = movie."id"
WHERE role.name='Bilbo'
AND movie.title like '%Smaug%'
