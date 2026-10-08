CREATE TABLE files (name TEXT, size INTEGER);
INSERT INTO files VALUES ('a.txt', 10), ('b.sql', 2000), ('c.txt', 300), ('d.md', 50), ('e.sql', 7);
SELECT substr(name, instr(name, '.') + 1) AS ext, count(*) AS n, sum(size) FROM files GROUP BY ext ORDER BY n DESC, ext;
SELECT CASE WHEN size < 100 THEN 'small' ELSE 'big' END AS cls, group_concat(name, ' ' ORDER BY name) FROM files GROUP BY cls ORDER BY cls;
SELECT length(name) AS len, count(*) FROM files GROUP BY len ORDER BY len;
SELECT max(size) AS m FROM files GROUP BY m;
