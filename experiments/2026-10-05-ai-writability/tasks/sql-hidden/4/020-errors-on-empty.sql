-- Each name error is reported even though no table has a row.
CREATE TABLE m (id INTEGER, v INTEGER);
CREATE TABLE n (id INTEGER, w INTEGER);
SELECT v, w FROM m JOIN n ON m.id = n.id ORDER BY id;
SELECT m.v FROM m AS mm;
SELECT n.* FROM m;
SELECT * FROM m JOIN n USING (v);
SELECT v FROM m WHERE coalesce((SELECT id, w FROM n), 0) = 1;
SELECT v FROM m WHERE v IN (SELECT * FROM n);
SELECT count(*) FROM m, n WHERE m.id = n.id;
SELECT (SELECT w FROM n), EXISTS (SELECT * FROM m);
