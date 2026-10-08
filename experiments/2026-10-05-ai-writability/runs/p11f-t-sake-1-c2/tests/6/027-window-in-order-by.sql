-- a window call in the final ORDER BY
CREATE TABLE w (name TEXT, team TEXT, goals INTEGER);
INSERT INTO w VALUES ('ana','red',3),('ben','blue',5),('cal','red',1),('dot','blue',2),('eli','red',4);
SELECT name FROM w ORDER BY row_number() OVER (ORDER BY goals DESC);
SELECT name, team FROM w ORDER BY sum(goals) OVER (PARTITION BY team) DESC, goals;
SELECT name, goals FROM w ORDER BY goals - avg(goals) OVER (PARTITION BY team), name;
SELECT name, rank() OVER (PARTITION BY team ORDER BY goals DESC) AS r FROM w ORDER BY r, name LIMIT 3;
