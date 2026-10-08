-- EXCEPT chains associate to the left
CREATE TABLE allnum (n INTEGER);
INSERT INTO allnum VALUES (1), (2), (3), (4), (5), (6), (6);
SELECT n FROM allnum EXCEPT SELECT n FROM allnum WHERE n % 2 = 0 EXCEPT SELECT 5 ORDER BY n;
SELECT n FROM allnum WHERE n > 3 EXCEPT SELECT n FROM allnum WHERE n > 4 ORDER BY n;
SELECT n FROM allnum EXCEPT SELECT n + 1 FROM allnum ORDER BY n;
SELECT 'a', 1 EXCEPT SELECT 'a', 2;
SELECT n FROM allnum EXCEPT SELECT n FROM allnum;
