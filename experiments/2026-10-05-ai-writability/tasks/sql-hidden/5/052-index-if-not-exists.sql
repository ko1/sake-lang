-- IF NOT EXISTS / IF EXISTS on indexes, and indexes leave results unchanged
CREATE TABLE word (w TEXT, n INTEGER);
INSERT INTO word VALUES ('b', 2), ('a', 1), ('c', 3), ('a', 4);
SELECT w, n FROM word WHERE w = 'a' ORDER BY n DESC;
CREATE INDEX word_w ON word (w);
CREATE INDEX IF NOT EXISTS word_w ON word (n);
CREATE INDEX IF NOT EXISTS word_wn ON word (w, n);
SELECT w, n FROM word WHERE w = 'a' ORDER BY n DESC;
SELECT w, sum(n) FROM word GROUP BY w ORDER BY w;
DROP INDEX IF EXISTS word_none;
DROP INDEX IF EXISTS word_w;
DROP INDEX word_w;
DROP INDEX word_wn;
CREATE UNIQUE INDEX IF NOT EXISTS word_w ON word (w);
CREATE UNIQUE INDEX IF NOT EXISTS word_n ON word (n);
INSERT INTO word VALUES ('d', 4);
SELECT count(*) FROM word;
