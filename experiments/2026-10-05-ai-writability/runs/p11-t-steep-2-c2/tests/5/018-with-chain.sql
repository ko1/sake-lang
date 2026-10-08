-- each cte is visible in the ctes after it and in the statement's subqueries
CREATE TABLE score (who TEXT, pts INTEGER);
INSERT INTO score VALUES ('a', 3), ('b', 9), ('c', 6), ('d', 1);
WITH s1 AS (SELECT who, pts * 2 AS p2 FROM score), s2 AS (SELECT who, p2 + 1 AS p3 FROM s1 WHERE p2 > 5) SELECT who, p3 FROM s2 ORDER BY p3;
WITH avgp AS (SELECT avg(pts) AS m FROM score) SELECT who FROM score WHERE pts > (SELECT m FROM avgp) ORDER BY who;
WITH top AS (SELECT who FROM score WHERE pts > 5) SELECT who, who IN (SELECT who FROM top) FROM score ORDER BY who;
WITH lo AS (SELECT 2 AS v), hi AS (SELECT v * 3 AS w FROM lo) SELECT v, w FROM lo, hi;
