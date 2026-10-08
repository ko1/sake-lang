-- q.rowid uses the source's alias; the table name is then unknown
CREATE TABLE author (aname TEXT);
CREATE TABLE book (title TEXT, aid INTEGER);
INSERT INTO author VALUES ('Woolf'), ('Eco'), ('Ende');
INSERT INTO book VALUES ('Rose', 2), ('Momo', 3), ('Waves', 1), ('Baudolino', 2);
SELECT a.rowid, aname, title FROM author AS a JOIN book AS b ON b.aid = a.rowid ORDER BY b.rowid;
SELECT author.rowid FROM author AS a;
SELECT x.oid, y._rowid_ FROM author x, book y WHERE x.rowid = 1 AND y.oid = 3;
