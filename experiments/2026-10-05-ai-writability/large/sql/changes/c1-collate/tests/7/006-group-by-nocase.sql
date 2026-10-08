-- GROUP BY puts values equal under the collation into one group.
CREATE TABLE hits (id INTEGER, host TEXT COLLATE NOCASE, path TEXT, ms INTEGER);
INSERT INTO hits VALUES (1, 'a.org', '/Home', 10), (2, 'A.ORG', '/home', 20), (3, 'b.org', '/home', 5),
  (4, 'A.org', '/HOME', 40), (5, 'B.ORG', '/about', 1);
SELECT lower(host), count(*), sum(ms) FROM hits GROUP BY host ORDER BY 1;
SELECT lower(path), count(*) FROM hits GROUP BY path ORDER BY 1, 2;
SELECT lower(path), count(*) FROM hits GROUP BY path COLLATE NOCASE ORDER BY 1;
SELECT count(*) FROM (SELECT host FROM hits GROUP BY 1);
SELECT lower(host) AS h, max(ms) FROM hits GROUP BY host HAVING host = 'B.Org' ORDER BY 1;
