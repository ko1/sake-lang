CREATE TABLE films (fid INTEGER, title TEXT);
CREATE TABLE casting (fid INTEGER, actor TEXT);
INSERT INTO films VALUES (1, 'Up'), (2, 'Heat'), (3, 'Jaws');
INSERT INTO casting VALUES (1, 'kim'), (2, 'kim'), (2, 'lee'), (3, 'lee'), (3, 'max'), (3, 'kim');
SELECT DISTINCT a.actor, b.actor FROM casting a JOIN casting b ON a.fid = b.fid AND a.actor < b.actor ORDER BY 1, 2;
SELECT count(DISTINCT actor), count(DISTINCT title), count(*) FROM films JOIN casting USING (fid);
SELECT DISTINCT title FROM films JOIN casting USING (fid) WHERE actor IN ('lee', 'max') ORDER BY title DESC;
SELECT actor, count(DISTINCT title) FROM casting JOIN films USING (fid) WHERE title <> 'Up' GROUP BY actor ORDER BY actor;
SELECT DISTINCT fid FROM casting WHERE actor IN (SELECT actor FROM casting WHERE fid = 1) ORDER BY fid;
