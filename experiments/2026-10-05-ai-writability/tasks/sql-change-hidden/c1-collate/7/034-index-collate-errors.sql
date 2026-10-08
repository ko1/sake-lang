-- A UNIQUE index with COLLATE fails on existing conflicts; an unknown name in an index is an error.
CREATE TABLE codes (c TEXT, d TEXT);
INSERT INTO codes VALUES ('ab ', 'x'), ('ab', 'X');
CREATE UNIQUE INDEX i1 ON codes (c COLLATE RTRIM);
CREATE UNIQUE INDEX i2 ON codes (d COLLATE Ascii);
CREATE UNIQUE INDEX i3 ON codes (c, d COLLATE NOCASE);
CREATE UNIQUE INDEX i4 ON codes (c COLLATE RTRIM, d);
INSERT INTO codes VALUES ('ab  ', 'x');
INSERT INTO codes VALUES ('ab  ', 'y');
SELECT count(*) FROM codes;
DROP INDEX i1;
