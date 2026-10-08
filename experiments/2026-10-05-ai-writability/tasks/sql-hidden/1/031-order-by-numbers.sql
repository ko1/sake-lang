CREATE TABLE r (team TEXT, pts INTEGER, gd INTEGER);
INSERT INTO r VALUES ('ox', 10, 3), ('elk', 12, -1), ('yak', 10, 5), ('emu', 7, 0), ('gnu', 12, 4);
SELECT team, pts, gd FROM r ORDER BY 2 DESC, 3 DESC;
SELECT pts, team FROM r ORDER BY 1, 2 DESC;
SELECT gd * 2, team FROM r ORDER BY 1;
SELECT * FROM r ORDER BY 3 DESC;
SELECT team FROM r ORDER BY 1 DESC LIMIT 2;
SELECT team, pts - gd FROM r ORDER BY 2, 1;
