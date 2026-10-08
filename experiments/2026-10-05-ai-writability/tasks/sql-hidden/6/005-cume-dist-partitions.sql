CREATE TABLE m (team TEXT, who TEXT, pts INTEGER);
INSERT INTO m VALUES ('a','p1',3),('a','p2',9),('a','p3',9),('a','p4',1),('b','q1',4),('b','q2',8),('c','r1',2);
SELECT who, cume_dist() OVER (PARTITION BY team ORDER BY pts) FROM m ORDER BY who;
SELECT who, cume_dist() OVER (PARTITION BY team ORDER BY pts DESC), cume_dist() OVER (PARTITION BY team) FROM m ORDER BY who;
SELECT who FROM m WHERE pts > 0 ORDER BY cume_dist() OVER (ORDER BY pts DESC), who;
SELECT team, typeof(cume_dist() OVER (PARTITION BY team ORDER BY pts)) FROM m WHERE who = 'r1';
