CREATE TABLE codes (c TEXT, n INTEGER);
INSERT INTO codes VALUES ('1', 1), ('01', 1), ('1', 2), ('1.0', 3), (' 1', 3);
SELECT count(DISTINCT c), count(DISTINCT n), count(DISTINCT c || n) FROM codes;
SELECT c, count(*) FROM codes GROUP BY c ORDER BY c;
SELECT DISTINCT c FROM codes WHERE n > 1 ORDER BY c;
SELECT group_concat(DISTINCT c ORDER BY c DESC) FROM codes;
