CREATE TABLE emp (dept TEXT, pay REAL);
SELECT count(*), total(pay), group_concat(dept, '+') FROM emp;
SELECT dept, count(*) FROM emp GROUP BY dept;
SELECT count(*) FROM emp HAVING count(*) = 0;
INSERT INTO emp VALUES ('x', 1.5);
DELETE FROM emp;
SELECT max(pay), min(dept), avg(pay), count(DISTINCT dept) FROM emp;
SELECT count(*) + 1, coalesce(sum(pay), 0) FROM emp;
SELECT dept FROM emp GROUP BY dept HAVING count(*) = 0;
