-- An unqualified name is looked up in the innermost query first.
CREATE TABLE outer_t (id INTEGER, val INTEGER);
CREATE TABLE inner_t (id INTEGER, val INTEGER, ref INTEGER);
INSERT INTO outer_t VALUES (1, 100), (2, 200);
INSERT INTO inner_t VALUES (1, 10, 2), (2, 20, 1), (3, 30, 1);
SELECT id, (SELECT sum(val) FROM inner_t WHERE ref = id) FROM outer_t ORDER BY id;
SELECT id, (SELECT sum(val) FROM inner_t WHERE ref = outer_t.id) FROM outer_t ORDER BY id;
SELECT id, outer_t.val + (SELECT sum(val) FROM inner_t WHERE ref = outer_t.id) FROM outer_t ORDER BY id;
SELECT id, (SELECT count(*) FROM inner_t i WHERE i.id <= outer_t.id) FROM outer_t ORDER BY id;
SELECT id FROM outer_t o WHERE (SELECT val FROM inner_t WHERE inner_t.id = o.id) * 10 = o.val ORDER BY id;
