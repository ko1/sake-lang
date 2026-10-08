CREATE TABLE m (team TEXT, who TEXT, pts INTEGER);
INSERT INTO m VALUES ('a','p1',3),('a','p2',9),('a','p3',9),('a','p4',1),('a','p5',6),('b','q1',4),('c','r1',2),('c','r2',2);
SELECT who, percent_rank() OVER (PARTITION BY team ORDER BY pts) FROM m ORDER BY who;
SELECT who, percent_rank() OVER (PARTITION BY team ORDER BY pts DESC), rank() OVER (PARTITION BY team ORDER BY pts DESC) FROM m ORDER BY who;
SELECT who, percent_rank() OVER (ORDER BY pts) * 7 FROM m ORDER BY who;
SELECT team, percent_rank() OVER (PARTITION BY team) FROM m WHERE team = 'b';
