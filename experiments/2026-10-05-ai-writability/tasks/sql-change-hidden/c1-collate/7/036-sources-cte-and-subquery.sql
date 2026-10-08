-- Columns of ctes (also renamed) and FROM subqueries keep their collation.
CREATE TABLE src (id INTEGER, k TEXT COLLATE RTRIM, plain TEXT);
INSERT INTO src VALUES (1, 'go  ', 'Go'), (2, 'stop', 'STOP'), (3, 'go', 'gO ');
WITH c AS (SELECT id, k FROM src) SELECT id FROM c WHERE k = 'go' ORDER BY id;
WITH c(n, kk) AS (SELECT id, k FROM src) SELECT n FROM c WHERE kk = 'go' ORDER BY n;
SELECT id FROM (SELECT id, plain COLLATE NOCASE AS p FROM src) WHERE p = 'go' ORDER BY id;
SELECT id FROM (SELECT id, plain AS p FROM src) WHERE p = 'go' ORDER BY id;
SELECT count(*) FROM (SELECT DISTINCT kk FROM (SELECT k AS kk FROM src));
