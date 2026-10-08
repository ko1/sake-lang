-- ctes holding aggregates, used in comparisons and scalar subqueries
CREATE TABLE score (team TEXT, pts INTEGER);
INSERT INTO score VALUES ('red', 3), ('red', 1), ('blue', 2), ('blue', 2), ('green', 7);
WITH tot AS (SELECT team, sum(pts) AS s FROM score GROUP BY team) SELECT team FROM tot WHERE s = (SELECT min(s) FROM tot) ORDER BY team;
WITH tot AS (SELECT team, sum(pts) AS s FROM score GROUP BY team) SELECT count(*), sum(s), group_concat(team, '/' ORDER BY s DESC, team) FROM tot;
WITH g AS (SELECT count(DISTINCT team) AS k FROM score) SELECT k, (SELECT count(*) FROM score) / k FROM g;
