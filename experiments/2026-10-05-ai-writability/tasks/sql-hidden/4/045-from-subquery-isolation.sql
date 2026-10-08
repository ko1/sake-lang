-- A subquery in FROM sees neither the other sources of its FROM nor later ones.
CREATE TABLE a (x INTEGER);
CREATE TABLE b (y INTEGER);
INSERT INTO a VALUES (1), (4);
INSERT INTO b VALUES (2), (3);
SELECT * FROM (SELECT y FROM b WHERE y > x) s, a;
SELECT * FROM a JOIN (SELECT y FROM b WHERE y = a.x) s ON 1;
SELECT * FROM a LEFT JOIN (SELECT y FROM b WHERE y > 2) s ON s.y > a.x ORDER BY x;
SELECT x, (SELECT count(*) FROM (SELECT y FROM b) s WHERE s.y > a.x) FROM a ORDER BY x;
