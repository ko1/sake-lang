-- scenario: page views split into sessions by gaps, then summarised
CREATE TABLE hit (id INTEGER PRIMARY KEY, usr TEXT NOT NULL, ts INTEGER NOT NULL, page TEXT);
INSERT INTO hit (usr, ts, page) VALUES ('u1',100,'home'),('u1',130,'shop'),('u1',160,'cart'),('u1',900,'home'),('u1',960,'help'),
  ('u2',50,'home'),('u2',400,'shop'),('u2',420,'shop'),('u2',440,'cart'),('u3',10,'help');
-- a new session starts after more than 120 seconds of silence
CREATE VIEW flagged AS SELECT id, usr, ts, page,
  CASE WHEN ts - lag(ts) OVER (PARTITION BY usr ORDER BY ts) <= 120 THEN 0 ELSE 1 END AS starts FROM hit;
SELECT usr, ts, starts FROM flagged ORDER BY usr, ts;
CREATE VIEW sess AS SELECT id, usr, ts, page, sum(starts) OVER (PARTITION BY usr ORDER BY ts) AS sid FROM flagged;
SELECT usr, ts, sid FROM sess ORDER BY usr, ts;
SELECT usr, sid, count(*) AS views, max(ts) - min(ts) AS secs FROM sess GROUP BY usr, sid ORDER BY usr, sid;
-- the path through each session
SELECT usr, sid, group_concat(page, '>' ORDER BY ts) FROM sess GROUP BY usr, sid ORDER BY usr, sid;
SELECT usr, ts, group_concat(page, '>') OVER (PARTITION BY usr, sid ORDER BY ts) FROM sess ORDER BY usr, ts;
-- next page and time spent on each
SELECT usr, page, lead(page, 1, 'exit') OVER (PARTITION BY usr, sid ORDER BY ts), lead(ts) OVER (PARTITION BY usr, sid ORDER BY ts) - ts FROM sess ORDER BY usr, ts;
-- busiest users
SELECT usr, count(*), dense_rank() OVER (ORDER BY count(*) DESC) FROM hit GROUP BY usr ORDER BY usr;
-- landing pages: first page of every session
SELECT page, count(*) FROM sess WHERE id IN (SELECT id FROM flagged WHERE starts = 1) GROUP BY page ORDER BY page;
SELECT usr, ts, ntile(2) OVER (PARTITION BY usr ORDER BY ts) FROM hit WHERE usr != 'u3' ORDER BY usr, ts;
INSERT INTO hit (usr, ts, page) VALUES ('u3', 100, 'home');
SELECT usr, sid, count(*) FROM sess WHERE usr = 'u3' GROUP BY usr, sid ORDER BY sid;
SELECT usr, ts, count(*) OVER (PARTITION BY usr ORDER BY ts RANGE BETWEEN 60 PRECEDING AND 60 FOLLOWING) FROM hit ORDER BY usr, ts;
SELECT id, page FROM hit ORDER BY count(*) OVER (PARTITION BY page) DESC, id LIMIT 4;
-- per-page popularity across users
SELECT page, count(*), rank() OVER (ORDER BY count(*) DESC) FROM hit GROUP BY page ORDER BY page;
SELECT usr, page, cume_dist() OVER (PARTITION BY usr ORDER BY ts) FROM hit WHERE usr = 'u1' ORDER BY ts;
DELETE FROM hit WHERE page = 'help';
SELECT usr, count(*), sum(count(*)) OVER (ORDER BY usr) FROM hit GROUP BY usr ORDER BY usr;
