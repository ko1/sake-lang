-- rows of one INSERT are numbered one after another, explicit rowids included
CREATE TABLE ev (name TEXT);
INSERT INTO ev (rowid, name) VALUES (NULL, 'a'), (NULL, 'b'), (8, 'c'), (NULL, 'd');
SELECT rowid, name FROM ev ORDER BY rowid;
INSERT INTO ev (rowid, name) VALUES (NULL, 'e'), (20, 'f'), (NULL, 'g');
SELECT rowid, name FROM ev ORDER BY rowid;
SELECT max(rowid) FROM ev;
