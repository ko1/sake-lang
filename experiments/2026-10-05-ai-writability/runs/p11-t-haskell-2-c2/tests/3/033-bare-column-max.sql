CREATE TABLE runners (name TEXT, club TEXT, secs INTEGER);
INSERT INTO runners VALUES ('ada', 'north', 610), ('bo', 'north', 590), ('cy', 'south', 640), ('di', 'south', 700), ('ed', 'north', 655);
SELECT name, max(secs) FROM runners;
SELECT club, name, max(secs) FROM runners GROUP BY club ORDER BY club;
SELECT name, club FROM runners GROUP BY club HAVING max(secs) > 0 ORDER BY club;
