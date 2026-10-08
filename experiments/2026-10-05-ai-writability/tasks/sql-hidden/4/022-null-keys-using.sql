CREATE TABLE lhs (k TEXT, v INTEGER);
CREATE TABLE rhs (k TEXT, w INTEGER);
INSERT INTO lhs VALUES ('a', 1), (NULL, 2), ('b', 3), (NULL, 4);
INSERT INTO rhs VALUES (NULL, 10), ('b', 30), ('b', 31);
SELECT k, v, w FROM lhs LEFT JOIN rhs USING (k) ORDER BY v, w;
SELECT count(*), count(w) FROM lhs LEFT JOIN rhs USING (k);
SELECT v, w FROM lhs JOIN rhs ON lhs.k IS rhs.k ORDER BY v, w;
SELECT v FROM lhs WHERE k NOT IN (SELECT k FROM rhs WHERE k IS NOT NULL) ORDER BY v;
