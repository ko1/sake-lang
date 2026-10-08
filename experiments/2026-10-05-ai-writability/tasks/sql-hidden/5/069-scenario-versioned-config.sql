-- scenario: versioned configuration; the latest value per skey through views and ctes
CREATE TABLE setting (skey TEXT NOT NULL, ver INTEGER NOT NULL, val TEXT, UNIQUE (skey, ver));
INSERT INTO setting VALUES ('color', 1, 'red'), ('color', 2, 'blue'), ('size', 1, '10'), ('mode', 1, 'dark'), ('mode', 3, 'light');
CREATE VIEW latest AS SELECT s.skey, s.val FROM setting s WHERE s.ver = (SELECT max(ver) FROM setting x WHERE x.skey = s.skey);
SELECT skey, val FROM latest ORDER BY skey;
INSERT INTO setting SELECT skey, max(ver) + 1, 'green' FROM setting WHERE skey = 'color' GROUP BY skey;
SELECT skey, val FROM latest WHERE skey = 'color';
INSERT INTO setting VALUES ('size', 1, '12');
BEGIN;
INSERT INTO setting SELECT skey, ver + 10, upper(val) FROM setting;
SELECT skey, val FROM latest ORDER BY skey;
ROLLBACK;
SELECT count(*) FROM setting;
WITH RECURSIVE v(n) AS (SELECT 1 UNION ALL SELECT n + 1 FROM v WHERE n < 3)
SELECT v.n, s.val FROM v LEFT JOIN setting s ON s.skey = 'mode' AND s.ver = v.n ORDER BY v.n;
SELECT skey FROM setting WHERE ver = 1 EXCEPT SELECT skey FROM setting WHERE ver > 1 ORDER BY skey;
SELECT skey, ver FROM setting WHERE val LIKE '%e%' UNION SELECT skey, 0 FROM latest ORDER BY skey, ver;
DROP VIEW latest;
ALTER TABLE setting RENAME TO config;
ALTER TABLE config ADD COLUMN note TEXT DEFAULT '';
INSERT INTO config (skey, ver) VALUES ('size', 2);
INSERT INTO config (skey, ver, val) VALUES (NULL, 9, 'x');
SELECT skey, ver, val, length(note) FROM config WHERE skey = 'size' ORDER BY ver;
CREATE VIEW latest AS SELECT skey, max(ver) AS v FROM config GROUP BY skey;
SELECT skey, v FROM latest ORDER BY v DESC, skey;
SELECT * FROM setting;
