CREATE TABLE emails (addr TEXT UNIQUE, n INTEGER);
INSERT INTO emails VALUES ('x@a', 1), ('y@a', 2), ('x@a', 3);
INSERT INTO emails VALUES ('x@a', 1);
DELETE FROM emails WHERE addr = 'x@a';
INSERT INTO emails VALUES ('x@a', 4), ('z@a', 5);
INSERT INTO emails VALUES ('w@a', 6), ('w@a', 7), ('v@a', 8);
INSERT INTO emails VALUES ('v@a', 8), ('u@a', 9), ('z@a', 10);
SELECT addr, n FROM emails ORDER BY n;
