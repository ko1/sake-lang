CREATE TABLE members (name TEXT, club TEXT);
CREATE TABLE clubs (club TEXT, open INTEGER);
INSERT INTO members VALUES ('ann', 'chess'), ('bob', 'golf'), ('cid', 'chess'), ('dee', 'polo');
INSERT INTO clubs VALUES ('chess', 1), ('golf', 0), ('tennis', 1);
SELECT name FROM members WHERE club IN (SELECT club FROM clubs) ORDER BY name;
SELECT name FROM members WHERE club IN (SELECT club FROM clubs WHERE open) ORDER BY name;
SELECT name FROM members WHERE club NOT IN (SELECT club FROM clubs WHERE open = 1) ORDER BY name;
SELECT club, club IN (SELECT club FROM members) FROM clubs ORDER BY club;
SELECT 'golf' IN (SELECT club FROM clubs WHERE open = 2), 'golf' NOT IN (SELECT club FROM clubs WHERE open = 2);
