-- the INTEGER PRIMARY KEY column changes with the rowid, and keeps its NOT NULL meaning for INSERT
CREATE TABLE emp (eid INTEGER NOT NULL PRIMARY KEY, ename TEXT);
INSERT INTO emp (ename) VALUES ('kim');
INSERT INTO emp (rowid, ename) VALUES (NULL, 'lee');
UPDATE emp SET rowid = rowid + 50;
SELECT eid, _rowid_, ename FROM emp ORDER BY eid;
UPDATE emp SET eid = NULL WHERE ename = 'kim';
INSERT INTO emp VALUES (52, 'moe');
SELECT count(*) FROM emp;
