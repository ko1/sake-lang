-- A ( select ) without an alias has no name but its columns are usable unqualified.
CREATE TABLE nums (n INTEGER);
INSERT INTO nums VALUES (1), (2), (3), (4);
SELECT * FROM (SELECT n, n * n AS sq FROM nums) ORDER BY n;
SELECT sq FROM (SELECT n * n AS sq FROM nums) WHERE sq > 4 ORDER BY sq;
SELECT n, d FROM nums, (SELECT 10 AS d) ORDER BY n;
SELECT count(*) FROM (SELECT n FROM nums WHERE n % 2 = 0);
SELECT * FROM (SELECT 'x' AS a, 2 AS b);
SELECT * FROM (SELECT n FROM nums WHERE n > 9);
