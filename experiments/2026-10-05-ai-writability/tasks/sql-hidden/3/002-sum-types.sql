CREATE TABLE vals (i INTEGER, r REAL, t TEXT);
INSERT INTO vals VALUES (1, 1.0, 'a'), (2, 2.0, 'b'), (3, 3.0, 'c');
SELECT sum(i), typeof(sum(i)), sum(r), typeof(sum(r)) FROM vals;
SELECT sum(i + r), sum(i * 2), sum(i / 2), sum(i / 2.0) FROM vals;
SELECT sum(t), typeof(sum(t)) FROM vals;
SELECT sum(-i), sum(i % 2) FROM vals;
SELECT typeof(sum(CASE WHEN i = 3 THEN 0.0 ELSE i END)) FROM vals;
