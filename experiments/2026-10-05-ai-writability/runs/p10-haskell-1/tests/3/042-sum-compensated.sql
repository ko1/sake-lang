CREATE TABLE f (id INTEGER PRIMARY KEY, v REAL);
INSERT INTO f (v) VALUES (0.1), (0.2), (1e16), (1.0);
SELECT sum(v), total(v) FROM f;
DELETE FROM f;
INSERT INTO f (v) VALUES (0.1), (0.2), (0.3);
SELECT sum(v), sum(v) = 0.6, avg(v) FROM f;
DELETE FROM f;
INSERT INTO f (v) VALUES (1e16), (1.0), (-1e16);
SELECT sum(v), total(v), avg(v) FROM f;
