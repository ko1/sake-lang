-- a given rowid is converted like an INTEGER column value or rejected
CREATE TABLE inv (sku TEXT);
INSERT INTO inv (rowid, sku) VALUES ('12', 'a'), (' 13', 'b'), (1e1, 'c');
SELECT rowid, sku FROM inv ORDER BY rowid;
INSERT INTO inv (rowid, sku) VALUES (14, 'd'), (14.5, 'e');
INSERT INTO inv (oid, sku) VALUES ('15x', 'f');
INSERT INTO inv (_rowid_, sku) VALUES (-3, 'g');
SELECT rowid, sku FROM inv ORDER BY rowid;
