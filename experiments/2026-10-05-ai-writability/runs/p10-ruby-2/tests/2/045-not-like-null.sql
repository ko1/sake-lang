SELECT 'abc' NOT LIKE 'a%', 'abc' NOT LIKE 'b%', NULL LIKE 'a', 'a' LIKE NULL, NULL NOT LIKE 'a';
SELECT NOT 'abc' LIKE 'x%', 'a' || 'b' LIKE 'AB';
CREATE TABLE f (name TEXT);
INSERT INTO f VALUES ('a.txt'), ('b.csv'), (NULL), ('c.TXT');
SELECT name FROM f WHERE name NOT LIKE '%.txt' ORDER BY name;
SELECT coalesce(name, 'none'), name LIKE '%.txt' FROM f ORDER BY name;
