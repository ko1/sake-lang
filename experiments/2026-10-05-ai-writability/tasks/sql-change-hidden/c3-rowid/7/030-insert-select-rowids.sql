-- the select may supply the rowids
CREATE TABLE a1 (t TEXT);
INSERT INTO a1 VALUES ('p'), ('q'), ('r');
CREATE TABLE a2 (t TEXT);
INSERT INTO a2 (rowid, t) SELECT rowid * 5, t FROM a1;
SELECT rowid, t FROM a2 ORDER BY rowid;
INSERT INTO a2 (oid, t) SELECT rowid + 4, upper(t) FROM a1;
INSERT INTO a2 (oid, t) SELECT rowid + 20, upper(t) FROM a1;
SELECT rowid, t FROM a2 ORDER BY rowid;
