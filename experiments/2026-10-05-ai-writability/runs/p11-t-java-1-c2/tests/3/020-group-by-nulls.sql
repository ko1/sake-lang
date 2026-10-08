CREATE TABLE tasks (team TEXT, hours INTEGER);
INSERT INTO tasks VALUES ('red', 2), (NULL, 3), ('blue', 4), (NULL, 5), ('red', NULL);
SELECT team, count(*), sum(hours) FROM tasks GROUP BY team ORDER BY team;
SELECT team, count(hours) FROM tasks GROUP BY team ORDER BY team NULLS LAST;
SELECT hours IS NULL, count(*) FROM tasks GROUP BY hours IS NULL ORDER BY 1;
