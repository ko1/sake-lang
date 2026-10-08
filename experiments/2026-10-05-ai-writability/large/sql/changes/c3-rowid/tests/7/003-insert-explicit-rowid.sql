-- an INSERT may give the rowid by naming it in the column list
CREATE TABLE seat (who TEXT);
INSERT INTO seat (rowid, who) VALUES (10, 'ann'), (3, 'bob');
INSERT INTO seat (oid, who) VALUES (' 7 ', 'cid');
INSERT INTO seat (_rowid_, who) VALUES (20.0, 'dan');
SELECT rowid, who FROM seat ORDER BY rowid;
INSERT INTO seat (rowid, who) VALUES (2.5, 'eve');
INSERT INTO seat (rowid, who) VALUES ('x1', 'eve');
INSERT INTO seat (rowid, who) VALUES (NULL, 'fay');
SELECT rowid, who FROM seat ORDER BY rowid;
INSERT INTO seat VALUES (rowid);
SELECT count(*) FROM seat;
