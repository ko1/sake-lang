-- Name errors happen before any row is read, so they occur on empty tables too.
CREATE TABLE a (k INTEGER, n TEXT);
CREATE TABLE b (k INTEGER, m TEXT);
SELECT k FROM a, b;
SELECT a.zz FROM a JOIN b ON a.k = b.k;
SELECT * FROM a JOIN b USING (n);
SELECT (SELECT k, n FROM a);
SELECT x.* FROM a;
SELECT n FROM a WHERE k IN (SELECT k, m FROM b);
SELECT count(*) FROM a JOIN b USING (k);
SELECT n, m FROM a LEFT JOIN b ON a.k = b.k;
