-- other primary keys are ordinary constraints beside a separate rowid
CREATE TABLE pr (k TEXT PRIMARY KEY, v INTEGER);
CREATE TABLE pc (a INTEGER, b INTEGER, PRIMARY KEY (a, b));
CREATE TABLE pu (k INTEGER UNIQUE);
INSERT INTO pr VALUES ('z', 1), ('y', 2);
INSERT INTO pc VALUES (50, 60), (70, 80);
INSERT INTO pu VALUES (90);
SELECT rowid, k FROM pr ORDER BY rowid;
SELECT rowid, a, b FROM pc ORDER BY rowid;
SELECT rowid, k FROM pu;
SELECT * FROM pc ORDER BY a;
