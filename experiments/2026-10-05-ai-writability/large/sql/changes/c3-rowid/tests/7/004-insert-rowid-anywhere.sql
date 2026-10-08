-- the rowid may stand anywhere in the column list; NULL means "assign one"
CREATE TABLE pet (kind TEXT, age INTEGER);
INSERT INTO pet (age, kind, rowid) VALUES (3, 'cat', 12);
INSERT INTO pet (kind, oid) VALUES ('dog', NULL), ('owl', 30);
INSERT INTO pet (rowid, kind, age) VALUES (NULL, 'eel', 1);
SELECT rowid, kind, age FROM pet ORDER BY rowid;
INSERT INTO pet VALUES ('yak', 2, 40);
INSERT INTO pet (rowid, kind) VALUES (50);
SELECT count(*), max(rowid) FROM pet;
