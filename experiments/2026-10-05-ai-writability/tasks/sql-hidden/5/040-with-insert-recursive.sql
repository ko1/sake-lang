-- WITH RECURSIVE ... INSERT fills a table from a generated sequence
CREATE TABLE cal (d INTEGER PRIMARY KEY, weekday TEXT);
WITH RECURSIVE days(n) AS (SELECT 1 UNION ALL SELECT n + 1 FROM days WHERE n < 14)
INSERT INTO cal SELECT n, CASE n % 7 WHEN 1 THEN 'mon' WHEN 2 THEN 'tue' WHEN 3 THEN 'wed' WHEN 4 THEN 'thu' WHEN 5 THEN 'fri' WHEN 6 THEN 'sat' ELSE 'sun' END FROM days;
SELECT weekday, count(*) FROM cal GROUP BY weekday ORDER BY min(d);
SELECT d FROM cal WHERE weekday IN ('sat', 'sun') ORDER BY d;
WITH RECURSIVE days(n) AS (SELECT 14 UNION ALL SELECT n + 1 FROM days WHERE n < 15) INSERT INTO cal SELECT n, 'x' FROM days;
WITH extra(n) AS (SELECT 20) INSERT INTO cal (d) SELECT n FROM extra;
SELECT max(d), count(*) FROM cal;
