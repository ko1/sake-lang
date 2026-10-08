-- a new row gets one more than the largest rowid present, 1 in an empty table
CREATE TABLE q (item TEXT);
INSERT INTO q VALUES ('a');
INSERT INTO q VALUES ('b'), ('c');
INSERT INTO q (rowid, item) VALUES (50, 'd');
INSERT INTO q VALUES ('e');
SELECT rowid, item FROM q ORDER BY rowid;
DELETE FROM q WHERE rowid >= 50;
INSERT INTO q VALUES ('f');
SELECT rowid, item FROM q ORDER BY rowid;
DELETE FROM q;
INSERT INTO q VALUES ('g');
SELECT rowid, item FROM q;
