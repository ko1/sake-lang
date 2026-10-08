CREATE TABLE r (id INTEGER, v REAL);
INSERT INTO r VALUES (1, 2.5), (2, NULL), (3, 1.0), (4, 2.5), (5, NULL), (6, 4.0), (7, 1);
SELECT id, v, rank() OVER (ORDER BY v), dense_rank() OVER (ORDER BY v) FROM r ORDER BY id;
SELECT id, rank() OVER (ORDER BY v DESC), dense_rank() OVER (ORDER BY v DESC) FROM r ORDER BY id;
SELECT id, rank() OVER (ORDER BY v NULLS LAST), dense_rank() OVER (ORDER BY v DESC NULLS FIRST) FROM r ORDER BY id;
