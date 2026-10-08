SELECT nullif(5, 5), nullif(5, 6), nullif(5, 5.0), nullif(5.0, 5);
SELECT nullif('x', 'x'), nullif('x', 'X'), nullif('5', 5), nullif(5, '5');
SELECT nullif(NULL, NULL), nullif(NULL, 'a'), nullif('a', NULL);
SELECT typeof(nullif(5, 6)), typeof(nullif(5.0, 5)), typeof(nullif('5', 5));
SELECT NULLIF(1, 1) IS NULL, NullIf(0, 0);
CREATE TABLE ni (k INTEGER, i INTEGER, r REAL, t TEXT);
INSERT INTO ni VALUES (1, 0, 0.0, '0'), (2, 3, 3.0, '3.0'), (4, 4, NULL, 'four');
SELECT k, nullif(i, r), nullif(t, i), nullif(i, t), nullif(t, '3.0') FROM ni ORDER BY k;
SELECT k, 12 / nullif(i, 0) FROM ni ORDER BY k;
