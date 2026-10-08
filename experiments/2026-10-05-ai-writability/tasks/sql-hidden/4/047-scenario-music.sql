-- Artists, albums and tracks.
CREATE TABLE artists (aid INTEGER PRIMARY KEY, name TEXT NOT NULL);
CREATE TABLE albums (alid INTEGER PRIMARY KEY, aid INTEGER, title TEXT, yr INTEGER);
CREATE TABLE tracks (alid INTEGER, no INTEGER, secs INTEGER, plays INTEGER DEFAULT 0, PRIMARY KEY (alid, no));
INSERT INTO artists (name) VALUES ('Aurora'), ('Bel'), ('Cato');
INSERT INTO albums VALUES (1, 1, 'Fjord', 2016), (2, 1, 'Echo', 2019), (3, 2, 'Lull', 2020);
INSERT INTO tracks VALUES (1, 1, 200, 50), (1, 2, 180, 10), (2, 1, 240, 70), (2, 2, 210, 5), (2, 3, 190, 0),
  (3, 1, 300, 20);
INSERT INTO tracks (alid, no, secs) VALUES (3, 2, 150);
INSERT INTO tracks VALUES (3, 1, 100, 1);
-- album lengths in minutes
SELECT title, sum(secs) / 60.0 FROM albums JOIN tracks USING (alid) GROUP BY title ORDER BY title;
-- artists with album and track counts
SELECT name, count(DISTINCT alid), count(no) FROM artists LEFT JOIN albums USING (aid) LEFT JOIN tracks USING (alid)
  GROUP BY aid ORDER BY name;
-- each artist's most played track
SELECT name, (SELECT title || '#' || no FROM albums JOIN tracks USING (alid) WHERE albums.aid = artists.aid
  ORDER BY plays DESC LIMIT 1) FROM artists ORDER BY name;
-- tracks played more than their album's average
SELECT title, no FROM albums a JOIN tracks t USING (alid)
  WHERE plays > (SELECT avg(plays) FROM tracks t2 WHERE t2.alid = a.alid) ORDER BY title, no;
-- latest album per artist
SELECT name, title FROM artists JOIN albums al USING (aid) WHERE yr = (SELECT max(yr) FROM albums WHERE aid = al.aid)
  ORDER BY name;
-- never played tracks get removed
DELETE FROM tracks WHERE plays = 0;
SELECT alid, no FROM tracks ORDER BY alid, no;
SELECT name FROM artists WHERE NOT EXISTS (SELECT 1 FROM albums WHERE albums.aid = artists.aid) ORDER BY name;
SELECT title FROM albums JOIN tracks ON albums.alid = tracks.alid WHERE alid = 3;
SELECT a.title, t.secs FROM albums a, tracks t WHERE t.alid = a.alid AND t.secs = (SELECT max(secs) FROM tracks);
SELECT * FROM artists JOIN albums USING (aid) JOIN tracks USING (yr);
SELECT name, sum(plays) FROM artists JOIN albums USING (aid) JOIN tracks USING (alid) GROUP BY name ORDER BY name;
