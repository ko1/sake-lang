-- scenario: a library's loans, member activity and overdue streaks
CREATE TABLE member (id INTEGER PRIMARY KEY, name TEXT NOT NULL, branch TEXT NOT NULL);
CREATE TABLE loan (id INTEGER PRIMARY KEY, member_id INTEGER NOT NULL, out_day INTEGER NOT NULL, back_day INTEGER, genre TEXT);
INSERT INTO member (name, branch) VALUES ('abe','west'),('bia','west'),('cho','east'),('dev','east'),('ema','east');
INSERT INTO loan (member_id, out_day, back_day, genre) VALUES (1,1,10,'sf'),(1,12,20,'crime'),(1,25,NULL,'sf'),(2,3,30,'poetry'),
  (3,2,5,'sf'),(3,6,9,'sf'),(3,10,14,'crime'),(3,15,NULL,'crime'),(4,8,40,'history');
INSERT INTO loan (member_id, out_day) VALUES (NULL, 50);
SELECT m.name, count(l.id) AS n, rank() OVER (ORDER BY count(l.id) DESC) FROM member AS m LEFT JOIN loan AS l ON l.member_id = m.id
  GROUP BY m.id ORDER BY n DESC, m.name;
SELECT member_id, id, out_day - lag(back_day) OVER (PARTITION BY member_id ORDER BY out_day) AS idle FROM loan ORDER BY member_id, out_day;
SELECT member_id, id, coalesce(back_day, 45) - out_day AS days, sum(coalesce(back_day, 45) - out_day) OVER (PARTITION BY member_id ORDER BY out_day) FROM loan ORDER BY id;
SELECT m.branch, m.name, row_number() OVER (PARTITION BY m.branch ORDER BY min(l.out_day)) FROM member AS m JOIN loan AS l ON l.member_id = m.id
  GROUP BY m.branch, m.name ORDER BY m.branch, m.name;
SELECT genre, count(*), dense_rank() OVER (ORDER BY count(*) DESC) AS pop FROM loan GROUP BY genre ORDER BY pop, genre;
CREATE VIEW open_loans AS SELECT member_id, id, out_day FROM loan WHERE back_day IS NULL;
SELECT member_id, id, count(*) OVER () FROM open_loans ORDER BY id;
SELECT id, genre, lag(genre, 1, '-') OVER (PARTITION BY member_id ORDER BY out_day) = genre AS same FROM loan ORDER BY id;
-- loans that started within the 10 days up to this one
SELECT id, out_day, count(*) OVER (ORDER BY out_day RANGE BETWEEN 10 PRECEDING AND CURRENT ROW) FROM loan WHERE out_day <= 15 ORDER BY id;
BEGIN;
UPDATE loan SET back_day = 46 WHERE back_day IS NULL;
SELECT member_id, max(back_day) - min(out_day), ntile(2) OVER (ORDER BY max(back_day) - min(out_day) DESC, member_id) FROM loan
  GROUP BY member_id ORDER BY member_id;
COMMIT;
SELECT count(*) FROM open_loans;
SELECT m.name, l.genre, first_value(l.genre) OVER (PARTITION BY m.id ORDER BY l.out_day) AS first_genre,
  last_value(l.genre) OVER (PARTITION BY m.id ORDER BY l.out_day ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS latest
  FROM member AS m JOIN loan AS l ON l.member_id = m.id WHERE m.branch = 'east' ORDER BY m.name, l.out_day;
DELETE FROM loan WHERE member_id = 3 AND genre = 'sf';
SELECT member_id, group_concat(id, ',') OVER (PARTITION BY member_id ORDER BY id) FROM loan WHERE member_id IN (1, 3) ORDER BY id;
SELECT name FROM member WHERE id NOT IN (SELECT member_id FROM loan WHERE member_id IS NOT NULL) ORDER BY name;
SELECT member_id, percent_rank() OVER (ORDER BY count(*)) FROM loan WHERE member_id IS NOT NULL GROUP BY member_id ORDER BY member_id;
