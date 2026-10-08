-- Subquery values flow into storage rules and constraints.
CREATE TABLE settings (k TEXT PRIMARY KEY, v INTEGER NOT NULL);
CREATE TABLE defaults (k TEXT, v TEXT);
INSERT INTO defaults VALUES ('width', '80'), ('height', '24.0'), ('ratio', '1.5'), ('name', 'term');
INSERT INTO settings VALUES ('width', (SELECT v FROM defaults WHERE k = 'width'));
INSERT INTO settings VALUES ('height', (SELECT v FROM defaults WHERE k = 'height'));
INSERT INTO settings VALUES ('ratio', (SELECT v FROM defaults WHERE k = 'ratio'));
INSERT INTO settings VALUES ('depth', (SELECT v FROM defaults WHERE k = 'depth'));
INSERT INTO settings VALUES ('name', (SELECT v FROM defaults WHERE k = 'name'));
SELECT k, v, typeof(v) FROM settings ORDER BY k;
UPDATE settings SET v = v * (SELECT count(*) FROM defaults) WHERE k IN (SELECT k FROM defaults WHERE v > '50');
SELECT k, v FROM settings ORDER BY k;
INSERT INTO settings VALUES ((SELECT k FROM defaults WHERE v = '80'), 1);
DELETE FROM settings WHERE k NOT IN (SELECT k FROM defaults WHERE length(v) = 2);
SELECT k, v FROM settings ORDER BY k;
