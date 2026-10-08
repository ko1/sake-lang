-- a real column named rowid in one source wins; USING cannot name a rowid
CREATE TABLE s1 (rowid TEXT, k INTEGER);
CREATE TABLE s2 (k INTEGER, v TEXT);
INSERT INTO s1 VALUES ('r', 1);
INSERT INTO s2 VALUES (1, 'one');
SELECT rowid, v FROM s1 JOIN s2 USING (k);
SELECT oid FROM s1 JOIN s2 USING (k);
SELECT v FROM s2 JOIN s2 AS t USING (rowid);
SELECT count(*) FROM s2 JOIN s2 AS t USING (k);
