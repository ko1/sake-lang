CREATE TABLE hits (site TEXT, n INTEGER);
INSERT INTO hits VALUES ('a', 1), ('b', 4), ('a', 2), ('c', 9), ('d', 4), ('b', 1), ('e', 7);
SELECT site, sum(n) AS s FROM hits GROUP BY site ORDER BY s DESC LIMIT 2;
SELECT site, sum(n) AS s FROM hits GROUP BY site ORDER BY s DESC LIMIT 2 OFFSET 2;
SELECT site FROM hits GROUP BY site ORDER BY site LIMIT -1 OFFSET 3;
SELECT count(*) FROM hits LIMIT 0;
SELECT count(*) FROM hits LIMIT 5 OFFSET 1;
