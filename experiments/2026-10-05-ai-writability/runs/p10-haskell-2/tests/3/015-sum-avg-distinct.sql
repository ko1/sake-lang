CREATE TABLE rolls (die INTEGER);
INSERT INTO rolls VALUES (3), (5), (3), (NULL), (6), (5);
SELECT sum(die), sum(DISTINCT die) FROM rolls;
SELECT avg(DISTINCT die), total(DISTINCT die) FROM rolls;
SELECT min(DISTINCT die), max(DISTINCT die) FROM rolls;
SELECT count(DISTINCT die % 2) FROM rolls;
