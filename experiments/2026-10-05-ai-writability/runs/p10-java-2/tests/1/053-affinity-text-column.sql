-- A TEXT column turns a number with no affinity into its text form.
CREATE TABLE t (id INTEGER, s TEXT);
INSERT INTO t VALUES (1, '12'), (2, '3.0'), (3, '10'), (4, 'abc'), (5, '1.5');
SELECT id FROM t WHERE s = 12;
SELECT id FROM t WHERE s = 3;
SELECT id FROM t WHERE s = 3.0;
SELECT id FROM t WHERE s < 5 ORDER BY id;
SELECT id FROM t WHERE s > 2 ORDER BY id;
SELECT id FROM t WHERE 1.5 = s;
SELECT id FROM t WHERE s = 1 + 2 * 5 - 1;
SELECT id, s = '12' FROM t WHERE id < 3 ORDER BY id;
