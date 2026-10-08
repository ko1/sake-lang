-- scenario: race results across heats, with positions, gaps and points
CREATE TABLE runner (bib INTEGER PRIMARY KEY, name TEXT UNIQUE, club TEXT);
CREATE TABLE result (heat INTEGER, bib INTEGER, secs REAL, UNIQUE (heat, bib));
INSERT INTO runner VALUES (11,'oz','rov'),(12,'pia','rov'),(13,'quin','fly'),(14,'rex','fly'),(15,'sam','cub');
INSERT INTO runner VALUES (16,'oz','cub');
INSERT INTO result VALUES (1,11,12.5),(1,12,12.25),(1,13,12.5),(1,14,13.0),(2,11,12.0),(2,13,11.75),(2,14,12.75),(2,15,12.0);
SELECT heat, bib, secs, rank() OVER (PARTITION BY heat ORDER BY secs) AS pos FROM result ORDER BY heat, pos, bib;
SELECT heat, bib, secs - first_value(secs) OVER (PARTITION BY heat ORDER BY secs) AS behind FROM result ORDER BY heat, secs, bib;
SELECT heat, bib, secs - lag(secs) OVER (PARTITION BY heat ORDER BY secs, bib) FROM result ORDER BY heat, secs, bib;
-- points: 10 for first, 6 for second, 3 for third, else 1 (ties share)
CREATE VIEW pts AS SELECT heat, bib, CASE rank() OVER (PARTITION BY heat ORDER BY secs) WHEN 1 THEN 10 WHEN 2 THEN 6 WHEN 3 THEN 3 ELSE 1 END AS p FROM result;
SELECT heat, bib, p FROM pts ORDER BY heat, bib;
SELECT r.name, sum(p.p) AS total, rank() OVER (ORDER BY sum(p.p) DESC) FROM pts AS p JOIN runner AS r USING (bib) GROUP BY r.name ORDER BY total DESC, r.name;
SELECT r.club, sum(p.p), dense_rank() OVER (ORDER BY sum(p.p) DESC) FROM pts AS p JOIN runner AS r ON r.bib = p.bib GROUP BY r.club ORDER BY r.club;
SELECT bib, min(secs), round(avg(secs), 3), cume_dist() OVER (ORDER BY min(secs)) FROM result GROUP BY bib ORDER BY bib;
-- a protest: heat 2 runner 13 disqualified
DELETE FROM result WHERE heat = 2 AND bib = 13;
SELECT heat, bib, p FROM pts WHERE heat = 2 ORDER BY bib;
SELECT heat, count(*), min(secs), max(secs) FROM result GROUP BY heat ORDER BY heat;
SELECT bib, heat, secs, avg(secs) OVER (PARTITION BY bib ORDER BY heat ROWS UNBOUNDED PRECEDING) FROM result ORDER BY bib, heat;
SELECT heat, bib, percent_rank() OVER (PARTITION BY heat ORDER BY secs DESC) FROM result ORDER BY heat, bib;
INSERT INTO result VALUES (3, 15, 11.5), (3, 12, 11.5), (3, 11, 11.0);
SELECT heat, bib, rank() OVER (w ORDER BY secs), dense_rank() OVER (w ORDER BY secs), row_number() OVER (w ORDER BY secs, bib) FROM result WHERE heat = 3
  WINDOW w AS (PARTITION BY heat) ORDER BY bib;
SELECT bib, count(*) OVER (PARTITION BY bib) FROM result WHERE heat > 1 ORDER BY heat, bib;
SELECT DISTINCT heat, nth_value(bib, 2) OVER (PARTITION BY heat ORDER BY secs, bib ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) FROM result ORDER BY heat;
