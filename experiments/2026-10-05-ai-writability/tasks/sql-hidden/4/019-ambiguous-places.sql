-- ambiguous column name in HAVING, in a function argument, in a subquery with two sources.
CREATE TABLE s1 (n INTEGER, a TEXT);
CREATE TABLE s2 (n INTEGER, b TEXT);
CREATE TABLE o (n INTEGER);
INSERT INTO s1 VALUES (1, 'p'), (2, 'q');
INSERT INTO s2 VALUES (2, 'r'), (2, 's');
INSERT INTO o VALUES (2);
SELECT a, count(*) FROM s1 JOIN s2 ON s1.n = s2.n GROUP BY a HAVING max(n) > 1;
SELECT upper(a), abs(n) FROM s1, s2;
SELECT n FROM o WHERE EXISTS (SELECT 1 FROM s1, s2 WHERE n = 2);
SELECT n FROM o WHERE EXISTS (SELECT 1 FROM s1 WHERE s1.n = n);
SELECT n FROM o WHERE EXISTS (SELECT 1 FROM s1 WHERE s1.n = o.n);
SELECT s1.n + s2.n, a || b FROM s1 JOIN s2 ON s1.n = s2.n ORDER BY 2;
SELECT a FROM s1 JOIN s2 USING (n) ORDER BY n, b;
