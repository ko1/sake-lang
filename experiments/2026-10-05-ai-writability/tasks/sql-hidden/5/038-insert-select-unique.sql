-- INSERT ... SELECT is all-or-nothing, rows checked one at a time against earlier ones
CREATE TABLE tag (name TEXT UNIQUE, n INTEGER NOT NULL);
CREATE TABLE incoming (name TEXT, n INTEGER);
INSERT INTO tag VALUES ('red', 1);
INSERT INTO incoming VALUES ('blue', 2), ('green', 3), ('blue', 4);
INSERT INTO tag SELECT name, n FROM incoming;
SELECT count(*) FROM tag;
INSERT INTO tag SELECT DISTINCT name, 0 FROM incoming;
SELECT name, n FROM tag ORDER BY name;
INSERT INTO tag SELECT 'pink', NULL UNION ALL SELECT 'red', 5;
INSERT INTO tag SELECT name || '2', n FROM tag;
SELECT name, n FROM tag ORDER BY name;
