-- The innermost subquery refers directly to the outermost query.
CREATE TABLE g (gid INTEGER, gname TEXT, minimum INTEGER);
CREATE TABLE m (gid INTEGER, uid INTEGER);
CREATE TABLE u (uid INTEGER, score INTEGER);
INSERT INTO g VALUES (1, 'alpha', 50), (2, 'beta', 80), (3, 'gamma', 0);
INSERT INTO m VALUES (1, 1), (1, 2), (2, 2), (2, 3), (3, 3);
INSERT INTO u VALUES (1, 40), (2, 90), (3, 85);
SELECT gname FROM g WHERE NOT EXISTS (SELECT 1 FROM m WHERE m.gid = g.gid AND EXISTS
  (SELECT 1 FROM u WHERE u.uid = m.uid AND u.score < g.minimum)) ORDER BY gname;
SELECT gname, (SELECT count(*) FROM m WHERE m.gid = g.gid AND uid IN
  (SELECT uid FROM u WHERE score >= minimum)) FROM g ORDER BY gid;
SELECT uid FROM u WHERE (SELECT count(*) FROM m WHERE m.uid = u.uid AND m.gid IN
  (SELECT gid FROM g WHERE minimum <= u.score)) = 2 ORDER BY uid;
