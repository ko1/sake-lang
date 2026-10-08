CREATE TABLE s (id INTEGER PRIMARY KEY, v INTEGER);
INSERT INTO s (v) VALUES (10), (20), (30);
UPDATE s SET v = v + rank() OVER (ORDER BY v);
UPDATE s SET v = 0 WHERE row_number() OVER () = 2;
DELETE FROM s WHERE id = lead(id) OVER (ORDER BY id);
INSERT INTO s (v) VALUES (cume_dist() OVER ());
-- window calls in the SELECT of INSERT ... SELECT and in a subquery of UPDATE are fine
INSERT INTO s (v) SELECT v * 10 + row_number() OVER (ORDER BY v) FROM s;
UPDATE s SET v = v + 1 WHERE id IN (SELECT id FROM (SELECT id, rank() OVER (ORDER BY v DESC) AS r FROM s) WHERE r <= 2);
SELECT id, v FROM s ORDER BY id;
