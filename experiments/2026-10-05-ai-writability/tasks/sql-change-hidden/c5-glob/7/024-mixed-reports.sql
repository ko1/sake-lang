CREATE TABLE events (id INTEGER PRIMARY KEY, kind TEXT, host TEXT, ms INTEGER);
INSERT INTO events (kind, host, ms) VALUES ('GET /a', 'web1', 12), ('GET /b', 'web2', 30), ('POST /a', 'web1', 55),
  ('get /c', 'db1', 7), ('GET /a', 'web2', 20), ('PUT /b', 'web10', 41);
WITH w AS (SELECT * FROM events WHERE host GLOB 'web[0-9]')
  SELECT host, count(*), max(ms) FROM w GROUP BY host ORDER BY host;
SELECT kind, count(*) FROM events GROUP BY kind HAVING kind GLOB 'GET *' ORDER BY kind;
SELECT id, rank() OVER (ORDER BY ms DESC) FROM events WHERE kind NOT GLOB 'G*' ORDER BY id;
SELECT id FROM events WHERE host IN (SELECT host FROM events WHERE kind GLOB 'P*') AND kind GLOB '*/a' ORDER BY id;
CREATE VIEW slow AS SELECT id, kind FROM events WHERE ms > 25;
SELECT kind FROM slow WHERE kind GLOB '*/[ab]' ORDER BY id;
