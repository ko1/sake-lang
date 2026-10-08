-- A UNIQUE index uses the column's collation, or its own COLLATE.
CREATE TABLE emails (addr TEXT COLLATE NOCASE, alias TEXT);
INSERT INTO emails VALUES ('x@y.z', 'Bo'), ('X@Y.Z', 'bo');
CREATE UNIQUE INDEX e1 ON emails (addr);
CREATE UNIQUE INDEX e2 ON emails (alias);
CREATE UNIQUE INDEX e3 ON emails (alias COLLATE NOCASE);
CREATE UNIQUE INDEX e4 ON emails (addr COLLATE BINARY);
INSERT INTO emails VALUES ('X@y.z', 'cy');
INSERT INTO emails VALUES ('q@r.s', 'BO');
INSERT INTO emails VALUES ('q@r.s', 'Dee');
SELECT addr, alias FROM emails ORDER BY addr COLLATE BINARY, alias COLLATE BINARY;
