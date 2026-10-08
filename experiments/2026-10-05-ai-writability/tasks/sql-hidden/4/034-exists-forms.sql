-- EXISTS only asks whether the subquery has a row.
CREATE TABLE ev (id INTEGER, kind TEXT, n INTEGER);
INSERT INTO ev VALUES (1, 'click', 3), (2, 'view', 0), (3, 'click', NULL);
SELECT EXISTS (SELECT 1 FROM ev LIMIT 0), EXISTS (SELECT 1 FROM ev LIMIT 1 OFFSET 2), EXISTS (SELECT 1 FROM ev LIMIT 1 OFFSET 3);
SELECT EXISTS (SELECT kind FROM ev GROUP BY kind HAVING count(*) > 2);
SELECT EXISTS (SELECT sum(n) FROM ev WHERE kind = 'none'), EXISTS (SELECT n FROM ev WHERE n IS NULL);
SELECT id, CASE WHEN NOT EXISTS (SELECT 1 FROM ev e2 WHERE e2.kind = ev.kind AND e2.id <> ev.id) THEN 'only'
  ELSE 'shared' END FROM ev ORDER BY id;
SELECT kind, count(*) FROM ev WHERE EXISTS (SELECT 1 FROM ev x WHERE x.id > ev.id) GROUP BY kind ORDER BY kind;
SELECT EXISTS (SELECT 1 FROM ev WHERE n > 2) AND NOT EXISTS (SELECT 1 FROM ev WHERE n > 5);
