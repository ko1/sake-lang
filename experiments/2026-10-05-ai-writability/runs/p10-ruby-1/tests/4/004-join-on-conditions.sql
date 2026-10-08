-- ON can be any condition, not only equality.
CREATE TABLE bands (lo INTEGER, hi INTEGER, grade TEXT);
CREATE TABLE scores (who TEXT, pts INTEGER);
INSERT INTO bands VALUES (0, 49, 'C'), (50, 79, 'B'), (80, 100, 'A');
INSERT INTO scores VALUES ('ann', 91), ('bob', 50), ('cid', 49), ('dee', 120);
SELECT who, grade FROM scores JOIN bands ON pts BETWEEN lo AND hi ORDER BY who;
SELECT who, grade FROM scores JOIN bands ON pts >= lo AND pts <= hi AND grade <> 'C' ORDER BY who;
SELECT s1.who, s2.who FROM scores s1 JOIN scores s2 ON s1.pts < s2.pts ORDER BY s1.who, s2.who;
SELECT who FROM scores JOIN bands ON 1 = 0 ORDER BY who;
SELECT count(*) FROM scores JOIN bands ON 'abc';
SELECT count(*) FROM scores JOIN bands ON '1x';
