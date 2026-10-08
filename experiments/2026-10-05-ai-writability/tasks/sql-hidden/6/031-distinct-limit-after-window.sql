CREATE TABLE o (id INTEGER, grp TEXT, val INTEGER);
INSERT INTO o VALUES (1,'p',3),(2,'q',3),(3,'p',5),(4,'r',1),(5,'q',4),(6,'p',2),(7,'r',1);
SELECT DISTINCT grp, max(val) OVER (PARTITION BY grp), count(*) OVER (PARTITION BY grp) FROM o ORDER BY grp;
SELECT DISTINCT rank() OVER (ORDER BY val) AS r FROM o ORDER BY r;
SELECT id, rank() OVER (ORDER BY val DESC) AS r FROM o ORDER BY r, id LIMIT 3;
SELECT id, row_number() OVER (ORDER BY id DESC) FROM o ORDER BY id LIMIT 3 OFFSET 2;
SELECT id, count(*) OVER () FROM o WHERE val > 2 ORDER BY id LIMIT 2;
SELECT DISTINCT val, ntile(2) OVER (ORDER BY val, id) FROM o WHERE val = 1 ORDER BY 2;
