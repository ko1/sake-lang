-- scenario: a game leaderboard with ties, percentiles and tiers
CREATE TABLE player (id INTEGER PRIMARY KEY, nick TEXT UNIQUE NOT NULL, country TEXT DEFAULT 'xx');
CREATE TABLE game (player_id INTEGER, round INTEGER, points INTEGER NOT NULL);
INSERT INTO player (nick, country) VALUES ('zed','fr'),('amy','de'),('kai','fr'),('bo','de'),('lia','it'),('max','fr');
INSERT INTO player (nick) VALUES ('new');
INSERT INTO game VALUES (1,1,40),(1,2,35),(2,1,50),(2,2,25),(3,1,20),(3,2,55),(4,1,30),(4,2,30),(5,1,70),(6,1,10),(6,2,15);
INSERT INTO game VALUES (7,1,NULL);
CREATE VIEW board AS SELECT p.nick, p.country, coalesce(sum(g.points), 0) AS pts, count(g.round) AS played
  FROM player AS p LEFT JOIN game AS g ON g.player_id = p.id GROUP BY p.id;
SELECT nick, pts, played FROM board ORDER BY pts DESC, nick;
SELECT nick, pts, rank() OVER (ORDER BY pts DESC) AS r, dense_rank() OVER (ORDER BY pts DESC) AS dr FROM board ORDER BY r, nick;
SELECT nick, round(percent_rank() OVER (ORDER BY pts), 3), round(cume_dist() OVER (ORDER BY pts), 3) FROM board ORDER BY pts, nick;
SELECT nick, ntile(3) OVER (ORDER BY pts DESC, nick) AS tier FROM board ORDER BY tier, nick;
SELECT country, nick, rank() OVER (PARTITION BY country ORDER BY pts DESC) FROM board ORDER BY country, nick;
SELECT country, count(*), max(pts), rank() OVER (ORDER BY max(pts) DESC) FROM board GROUP BY country ORDER BY country;
-- gap to the player above
SELECT nick, pts, lag(pts) OVER (ORDER BY pts DESC, nick) - pts AS gap FROM board ORDER BY pts DESC, nick;
-- leader of each country
SELECT DISTINCT country, first_value(nick) OVER (PARTITION BY country ORDER BY pts DESC, nick) AS leader FROM board
  WHERE country != 'xx' ORDER BY country;
-- a third round
BEGIN;
INSERT INTO game VALUES (2,3,20),(4,3,25),(5,2,0);
SELECT nick, pts, rank() OVER (ORDER BY pts DESC) FROM board WHERE played >= 2 ORDER BY pts DESC, nick;
ROLLBACK;
SELECT nick, pts, rank() OVER (ORDER BY pts DESC) FROM board WHERE played >= 2 ORDER BY pts DESC, nick;
SELECT DISTINCT country, sum(pts) OVER (PARTITION BY country) FROM board ORDER BY 2 DESC, 1;
SELECT nick, pts FROM board ORDER BY rank() OVER (ORDER BY pts), nick LIMIT 2;
