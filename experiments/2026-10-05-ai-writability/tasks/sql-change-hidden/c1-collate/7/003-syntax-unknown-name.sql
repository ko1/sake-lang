-- Unknown collation names fail in a table definition and in expressions, even on an empty table.
CREATE TABLE w (a TEXT, b TEXT COLLATE german);
CREATE TABLE w (a TEXT COLLATE Nocase, b TEXT);
SELECT count(*) FROM w WHERE a = 'x' COLLATE Klingon;
SELECT a FROM w ORDER BY b COLLATE Weird;
INSERT INTO w VALUES ('A', 'b');
SELECT a COLLATE NOCASE FROM w WHERE a COLLATE Missing < 'z';
SELECT a, b FROM w WHERE a = 'a';
