CREATE TABLE scores (who TEXT, pts INTEGER);
INSERT INTO scores VALUES ('a', 1), ('b', 2), ('c', 4), ('d', NULL);
SELECT avg(pts), typeof(avg(pts)) FROM scores;
SELECT avg(pts) FROM scores WHERE pts < 3;
SELECT avg(pts) FROM scores WHERE pts IS NULL;
SELECT avg(pts * 1.0) FROM scores WHERE pts > 1;
SELECT avg(pts) FROM scores WHERE who = 'c';
