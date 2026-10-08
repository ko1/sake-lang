-- scenario: a round-robin tournament built with ctes and compound selects
CREATE TABLE team (name TEXT PRIMARY KEY);
CREATE TABLE game (home TEXT, away TEXT, hg INTEGER, ag INTEGER, UNIQUE (home, away));
INSERT INTO team VALUES ('ants'), ('bees'), ('cats'), ('dogs');
INSERT INTO game SELECT a.name, b.name, NULL, NULL FROM team a JOIN team b ON a.name < b.name;
SELECT count(*) FROM game;
UPDATE game SET hg = 2, ag = 1 WHERE home = 'ants' AND away = 'bees';
UPDATE game SET hg = 0, ag = 0 WHERE home = 'ants' AND away = 'cats';
UPDATE game SET hg = 1, ag = 3 WHERE home = 'ants' AND away = 'dogs';
UPDATE game SET hg = 2, ag = 2 WHERE home = 'bees' AND away = 'cats';
UPDATE game SET hg = 4, ag = 0 WHERE home = 'bees' AND away = 'dogs';
CREATE VIEW result AS SELECT home AS t, hg AS gf, ag AS ga FROM game WHERE hg IS NOT NULL UNION ALL SELECT away, ag, hg FROM game WHERE hg IS NOT NULL;
WITH pts AS (SELECT t, CASE WHEN gf > ga THEN 3 WHEN gf = ga THEN 1 ELSE 0 END AS p, gf - ga AS gd FROM result)
SELECT t, sum(p), sum(gd), count(*) FROM pts GROUP BY t ORDER BY sum(p) DESC, sum(gd) DESC, t;
SELECT home, away FROM game WHERE hg IS NULL;
SELECT t FROM result WHERE gf > ga INTERSECT SELECT t FROM result WHERE gf < ga ORDER BY t;
SELECT name FROM team EXCEPT SELECT t FROM result WHERE gf > ga ORDER BY name;
INSERT INTO game VALUES ('ants', 'bees', 0, 0);
INSERT INTO game SELECT away, home, NULL, NULL FROM game WHERE home = 'ants';
SELECT count(*) FROM game;
SELECT max(gf), min(ga) FROM result;
SELECT home AS team, hg AS goals FROM game WHERE hg > 1 UNION SELECT away, ag FROM game WHERE ag > 1 ORDER BY goals DESC, team;
UPDATE result SET gf = 0;
