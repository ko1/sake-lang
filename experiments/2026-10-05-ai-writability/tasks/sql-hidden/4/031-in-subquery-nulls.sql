-- Three-valued IN / NOT IN with subqueries, seen through CASE and WHERE.
CREATE TABLE codes (c INTEGER);
CREATE TABLE allowed (c INTEGER);
INSERT INTO codes VALUES (1), (2), (3), (NULL);
INSERT INTO allowed VALUES (1), (NULL);
SELECT c, CASE WHEN c IN (SELECT c FROM allowed) THEN 'in' WHEN c NOT IN (SELECT c FROM allowed) THEN 'out'
  ELSE 'unknown' END FROM codes ORDER BY c;
SELECT c FROM codes WHERE c NOT IN (SELECT c FROM allowed WHERE c IS NOT NULL) ORDER BY c;
SELECT c FROM codes WHERE NOT (c NOT IN (SELECT c FROM allowed)) ORDER BY c;
SELECT typeof(NULL IN (SELECT c FROM allowed)), typeof(3 IN (SELECT c FROM allowed WHERE c = 1));
SELECT c, c IN (SELECT c + 1 FROM allowed) FROM codes ORDER BY c DESC;
