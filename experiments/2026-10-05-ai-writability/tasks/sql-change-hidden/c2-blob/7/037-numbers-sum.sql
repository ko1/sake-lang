CREATE TABLE amt (k INTEGER, b BLOB);
INSERT INTO amt VALUES (1, X'3130'), (2, X'35'), (3, X'7A'), (4, NULL);
SELECT sum(b), typeof(sum(b)), total(b), avg(b) FROM amt;
SELECT sum(b), typeof(sum(b)) FROM amt WHERE k = 1;
SELECT sum(x), typeof(sum(x)) FROM (SELECT 2 AS x UNION ALL SELECT X'33');
