-- the specification's examples, with the arguments taken from stored rows
CREATE TABLE sx (id INTEGER PRIMARY KEY, s TEXT, p INTEGER, q INTEGER);
INSERT INTO sx (s, p, q) VALUES ('hello', 2, NULL), ('hello', 0, 2), ('hello', -3, 2), ('hello', 2, -1), (12345, 2, 2);
SELECT id, CASE WHEN q IS NULL THEN substr(s, p) ELSE substr(s, p, q) END FROM sx ORDER BY id;
CREATE TABLE rx (x REAL, n INTEGER);
INSERT INTO rx VALUES (2.5, NULL), (-2.5, NULL), (2.345, 2), (1.005, 2), (5, NULL);
SELECT x, CASE WHEN n IS NULL THEN round(x) ELSE round(x, n) END FROM rx ORDER BY x;
CREATE TABLE cx (t TEXT);
INSERT INTO cx VALUES ('12abc'), ('1e3'), ('1.9'), ('abc');
SELECT t, CAST(t AS INTEGER), CAST(t AS REAL) FROM cx ORDER BY t;
SELECT t, replace(t, '', 'z'), t LIKE upper(t) FROM cx ORDER BY t;
