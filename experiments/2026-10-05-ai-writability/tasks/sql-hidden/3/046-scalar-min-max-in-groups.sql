CREATE TABLE games (team TEXT, home INTEGER, away INTEGER);
INSERT INTO games VALUES ('x', 3, 1), ('x', 0, 2), ('y', 4, 4), ('y', 1, 5), ('y', NULL, 2);
SELECT team, sum(max(home, away)), sum(min(home, away)) FROM games GROUP BY team ORDER BY team;
SELECT team, max(home), max(away), max(home, away, 3) FROM games WHERE home IS NOT NULL GROUP BY team, home, away ORDER BY team, home;
SELECT max(sum(home), 5) FROM games;
SELECT team, min(count(*), 2) FROM games GROUP BY team ORDER BY team;
