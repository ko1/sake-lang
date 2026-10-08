-- a view is a named select used as a source
CREATE TABLE emp (name TEXT, dept TEXT, salary INTEGER);
INSERT INTO emp VALUES ('ann', 'dev', 100), ('bob', 'ops', 80), ('cy', 'dev', 120), ('di', 'hr', 90);
CREATE VIEW devs AS SELECT name, salary FROM emp WHERE dept = 'dev';
SELECT name, salary FROM devs ORDER BY name;
SELECT * FROM devs ORDER BY salary DESC;
CREATE VIEW payroll AS SELECT dept, sum(salary) AS total FROM emp GROUP BY dept;
SELECT dept, total FROM payroll ORDER BY total DESC;
SELECT e.name FROM emp e JOIN payroll p ON p.dept = e.dept WHERE p.total > 150 ORDER BY e.name;
SELECT (SELECT total FROM payroll WHERE dept = 'hr');
