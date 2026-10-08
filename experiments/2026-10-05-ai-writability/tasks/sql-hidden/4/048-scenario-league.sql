-- A football league: matches reference the teams table twice.
CREATE TABLE teams (tid INTEGER PRIMARY KEY, tname TEXT UNIQUE NOT NULL, city TEXT);
CREATE TABLE matches (mid INTEGER PRIMARY KEY, home INTEGER, away INTEGER, hg INTEGER, ag INTEGER);
INSERT INTO teams (tname, city) VALUES ('Lions', 'Ash'), ('Hawks', 'Birch'), ('Bears', 'Ash'), ('Wolves', 'Cedar');
INSERT INTO matches (home, away, hg, ag) VALUES (1, 2, 2, 1), (2, 3, 0, 0), (3, 1, 1, 3), (4, 1, 2, 2), (2, 4, 3, 1);
INSERT INTO teams (tname) VALUES ('Hawks');
-- results with names
SELECT mid, h.tname, a.tname, hg || '-' || ag FROM matches JOIN teams h ON h.tid = home JOIN teams a ON a.tid = away
  ORDER BY mid;
-- points: 3 for a win, 1 for a draw, home and away together
SELECT tname, (SELECT total(CASE WHEN hg > ag THEN 3 WHEN hg = ag THEN 1 ELSE 0 END) FROM matches WHERE home = tid)
  + (SELECT total(CASE WHEN ag > hg THEN 3 WHEN hg = ag THEN 1 ELSE 0 END) FROM matches WHERE away = tid) AS pts
  FROM teams ORDER BY pts DESC, tname;
-- goals scored per team
SELECT tname, sum(CASE WHEN tid = home THEN hg ELSE ag END) AS gf FROM teams JOIN matches ON tid = home OR tid = away
  GROUP BY tid ORDER BY gf DESC, tname;
-- derbies: both teams from the same city
SELECT mid FROM matches m JOIN teams h ON h.tid = m.home JOIN teams a ON a.tid = m.away WHERE h.city = a.city;
-- teams that never lost at home
SELECT tname FROM teams WHERE tid NOT IN (SELECT home FROM matches WHERE hg < ag) ORDER BY tname;
-- teams that never scored twice at home
SELECT tname FROM teams t LEFT JOIN matches m ON m.home = t.tid AND m.hg > 1 WHERE m.mid IS NULL ORDER BY tname;
-- the biggest win
SELECT h.tname, a.tname FROM matches JOIN teams h ON h.tid = home JOIN teams a ON a.tid = away
  WHERE abs(hg - ag) = (SELECT max(abs(hg - ag)) FROM matches) ORDER BY mid;
UPDATE matches SET ag = ag + 1 WHERE mid = (SELECT max(mid) FROM matches WHERE home = 2);
SELECT mid, hg, ag FROM matches WHERE home IN (SELECT tid FROM teams WHERE tname = 'Hawks') ORDER BY mid;
SELECT tname FROM teams JOIN matches ON tid = home WHERE city = 'Ash' AND hg > ag;
SELECT tname, city FROM teams h JOIN teams a ON h.city = a.city WHERE h.tid < a.tid;
SELECT tname FROM teams WHERE tid IN (SELECT home, away FROM matches);
SELECT city, count(*) FROM teams JOIN matches ON tid = home GROUP BY city ORDER BY city;
DELETE FROM matches WHERE away IN (SELECT tid FROM teams WHERE city = 'Cedar');
SELECT count(*), sum(hg + ag) FROM matches;
