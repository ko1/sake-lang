-- numbering counts the rows present now
CREATE TABLE tk (n TEXT);
INSERT INTO tk VALUES ('a'), ('b'), ('c'), ('d');
DELETE FROM tk WHERE rowid IN (2, 4);
INSERT INTO tk VALUES ('e');
SELECT rowid, n FROM tk ORDER BY rowid;
DELETE FROM tk WHERE n <> 'a';
INSERT INTO tk VALUES ('f'), ('g');
SELECT rowid, n FROM tk ORDER BY rowid;
