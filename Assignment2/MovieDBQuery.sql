a)
drop function title_count(character varying);
CREATE OR REPLACE FUNCTION title_count(p_name varchar(20))
	returns integer as $$
	declare d_count integer;
	begin
					SELECT COUNT
						( DISTINCT movie_id ) into d_count
					FROM
						casting C,
						person P,
						movie M
					WHERE
						C.person_id = P.ID
						AND C.movie_id = M.ID
						AND M.kind = 'movie'
						AND C.role_type = 'actor'
						AND P.NAME LIKE p_name;
			return d_count;
	end;
	$$
	language plpgsql;
	SELECT title_count('Bacon, Kevin');
  ----------------------------------------------------
  b)
  drop function title_count(character varying, character varying, character varying);
CREATE OR REPLACE FUNCTION title_count(actor_name varchar(20), movie_kind varchar(20), actor_role_type varchar(20))
	returns integer as $$
	declare d_count integer;
	begin
					SELECT COUNT
						( DISTINCT movie_id ) into d_count
					FROM
						casting C,
						person P,
						movie M
					WHERE
						C.person_id = P.ID
						AND C.movie_id = M.ID
						AND M.kind = movie_kind
						AND C.role_type = actor_role_type
						AND P.NAME LIKE actor_name;
			return d_count;
	end;
	$$
	language plpgsql;
  ----------------------------------------------------
  c)
  CREATE OR REPLACE FUNCTION title_count(actor_name varchar(20), movie_kind varchar(20) default '%', actor_role_type varchar(20) default '%')
	returns integer as $$
	declare d_count integer;
	begin
					SELECT COUNT
						( DISTINCT movie_id ) into d_count
					FROM
						casting C,
						person P,
						movie M
					WHERE
						C.person_id = P.ID
						AND C.movie_id = M.ID
						AND M.kind like movie_kind
						AND C.role_type like actor_role_type
						AND P.NAME LIKE actor_name;
			return d_count;
	end;
	$$
	language plpgsql;
SELECT title_count('Bacon, Kevin');

----------------------------------------------------
d)
create or replace function movies (actor_name char(20))
returns TABLE (title char (100), production_year int)
as
$$
 SELECT (title, production_year)
        FROM casting c, person p, movie m
        WHERE c.person_id = p.id
                AND c.movie_id = m.id
               /* AND m.kind like s_kind
                AND c.role_type like srole_type*/
        AND p.name like actor_name
				and m.kind='movie';
$$
language sql;

----------------------------------------------------
e)
CREATE or replace FUNCTION match_title(movie_title varchar(100))
returns table (
	title varchar(30),
	production_year int) as
$$
		SELECT title, production_year
		FROM movie
		WHERE movie.title
		like  concat('%',movie_title, '%')
		AND movie.kind = 'movie'
		AND production_year is not NULL
		order by production_year ASC
		limit 10;

$$
language sql;


SELECT * from match_title('Wonderful');
----------------------------------------------------
f)
CREATE or REPLACE FUNCTION collect_role_types(person_name text)
returns text as $$

declare role_types text default '';
collect_type_record record;
cursor_collect cursor for SELECT DISTINCT role_type
FROM casting, person
WHERE casting.person_id = person.id
AND name like person_name;

begin
		open cursor_collect;
		loop
			fetch cursor_collect into collect_type_record;
			exit when not found;
			RAISE WARNING 'log message %', collect_type_record;
			role_types :=  role_types || ',' || collect_type_record;
		end loop;
	close cursor_collect;
	return role_types;
end;
$$
language plpgsql;



----------------------------------------------------
g)
CREATE or REPLACE FUNCTION collect_role_types(person_name TEXT)
returns TEXT as $$
DECLARE
types TEXT DEFAULT '';
collect_type_record record;

begin
	  for collect_type_record in
		SELECT DISTINCT role_type
		from casting, person
	  WHERE casting.person_id = person.id
	  AND person.name = person_name loop

	 types :=  types || ','  || collect_type_record.role_type;
	 raise notice '%', types;

end loop;
	return types;
end;
$$
language plpgsql;

SELECT collect_role_types('Bacon, Kevin');
SELECT name, collect_role_types(name)
FROM person where name like 'De Niro, R%';


----------------------------------------------------
h)
-- first, we need a function to collect all role types for person by their ids
drop function if exists collect_role_types_for(person_idd int);
CREATE or REPLACE FUNCTION collect_role_types_for(person_idd int)
returns text as $$

declare role_types text default '';
rec record;
begin
	for rec in
	SELECT DISTINCT role_type
	FROM casting, person
	WHERE casting.person_id = person.id
	and person.id = person_idd
	loop
		role_types :=  role_types || ',' || rec.role_type;
	end loop;
	return role_types;
	end;
$$
language plpgsql;

-- SELECT collect_role_types_for(103491);

--secondly, we define a trigger for casting table and the trigger functionality
drop trigger if exists trigger_role_types on casting;
drop function if exists check_role_type();

create or replace function update_role_type()
	returns trigger as $$
	begin
		UPDATE person
		SET role_types = collect_role_types
		FROM (SELECT collect_role_types_for(NEW.person_id)) collect_role_types
		WHERE person.id=NEW.person_id;
		return new;
	end; $$
language plpgsql;

create trigger trigger_role_types
after insert on casting
for each row execute procedure update_role_type();

--thirdly, we insert a new record in the casting table
insert into casting values (129911211,103491, 2, null, 'batman')
-- lastly, we check if person has role_types updated
select * from person where person.id = 103491
