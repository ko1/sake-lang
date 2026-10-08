-- Which texts parse as numbers when stored into numeric columns.
CREATE TABLE t (k INTEGER, i INTEGER, r REAL);
INSERT INTO t VALUES (1, '42', '42');
INSERT INTO t VALUES (2, '-0', '-0.25');
INSERT INTO t VALUES (3, '  +15', '2.5E1  ');
INSERT INTO t VALUES (4, '5.0', '1e-2');
INSERT INTO t VALUES (5, '12abc', 1);
INSERT INTO t VALUES (6, 1, '0x10');
INSERT INTO t VALUES (7, '', 1);
INSERT INTO t VALUES (8, 1, '1 2');
INSERT INTO t VALUES (9, 1, '- 3');
SELECT k, i, typeof(i), r, typeof(r) FROM t ORDER BY k;
