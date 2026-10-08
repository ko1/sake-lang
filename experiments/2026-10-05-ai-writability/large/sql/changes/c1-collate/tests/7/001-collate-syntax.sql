-- COLLATE in a column definition (in any position, any case) and as a postfix operator.
CREATE TABLE people (id INTEGER PRIMARY KEY, name TEXT COLLATE NOCASE NOT NULL, nick TEXT NOT NULL COLLATE rtrim, tag TEXT);
INSERT INTO people (name, nick, tag) VALUES ('Alice', 'al  ', 'Red'), ('BOB', 'bob', 'blue');
SELECT id FROM people WHERE name = 'alice';
SELECT id FROM people WHERE nick = 'al';
SELECT id FROM people WHERE tag = 'red';
SELECT id FROM people WHERE tag COLLATE NOCASE = 'red';
SELECT id FROM people WHERE tag COLLATE nocase = 'BLUE';
SELECT name COLLATE BINARY = 'alice', name = 'ALICE' FROM people WHERE id = 1;
SELECT 'abc' COLLATE NoCase = 'ABC', 'abc' = 'ABC', 'x' || 'y' COLLATE NOCASE;
SELECT nick, length(nick), typeof(name COLLATE NOCASE) FROM people WHERE id = 1;
CREATE TABLE nums (i INTEGER, s TEXT);
INSERT INTO nums VALUES (12, '12');
SELECT i COLLATE NOCASE = '12', s COLLATE NOCASE = 12, i COLLATE RTRIM + 1 FROM nums;
