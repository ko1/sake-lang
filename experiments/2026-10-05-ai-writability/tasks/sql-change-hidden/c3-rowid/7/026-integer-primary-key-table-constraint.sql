-- PRIMARY KEY (c) on one INTEGER column is the rowid too
CREATE TABLE part (pno INTEGER, pname TEXT, PRIMARY KEY (pno));
INSERT INTO part (pname) VALUES ('bolt'), ('nut');
INSERT INTO part VALUES (10, 'gear');
INSERT INTO part (oid, pname) VALUES (NULL, 'cog');
SELECT pno, rowid, pname FROM part ORDER BY pno;
INSERT INTO part (_rowid_, pname) VALUES (10, 'pin');
UPDATE part SET pno = 'x' WHERE pname = 'nut';
SELECT * FROM part WHERE oid = 11;
