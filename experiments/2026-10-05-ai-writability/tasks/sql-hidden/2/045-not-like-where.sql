CREATE TABLE u (name TEXT, mail TEXT);
INSERT INTO u VALUES ('ann', 'ann@corp.com'), ('bob', NULL), ('cy', 'cy@home.org'), ('dee', 'DEE@CORP.COM');
SELECT name FROM u WHERE mail NOT LIKE '%@corp.com' ORDER BY name;
SELECT name FROM u WHERE NOT mail LIKE '%.org' ORDER BY name;
SELECT name, mail LIKE '%corp%', mail NOT LIKE '%corp%' FROM u ORDER BY name;
SELECT name FROM u WHERE (mail LIKE '%corp%') IS NULL ORDER BY name;
