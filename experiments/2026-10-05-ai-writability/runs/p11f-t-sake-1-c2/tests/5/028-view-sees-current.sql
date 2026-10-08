-- a view runs anew wherever it is used, so it sees the tables as they are then
CREATE TABLE t (v INTEGER);
CREATE VIEW big AS SELECT v FROM t WHERE v > 10;
SELECT count(*) FROM big;
INSERT INTO t VALUES (5), (15), (25);
SELECT v FROM big ORDER BY v;
UPDATE t SET v = v + 10;
SELECT v FROM big ORDER BY v;
DELETE FROM t WHERE v = 35;
SELECT v FROM big ORDER BY v;
