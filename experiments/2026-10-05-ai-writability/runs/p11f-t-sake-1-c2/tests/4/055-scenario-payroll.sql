-- Departments, employees and monthly pay, with derived tables.
CREATE TABLE dept (did INTEGER PRIMARY KEY, dname TEXT NOT NULL);
CREATE TABLE emp (eid INTEGER PRIMARY KEY, name TEXT, did INTEGER, salary INTEGER);
CREATE TABLE bonus (eid INTEGER, month INTEGER, amount INTEGER);
INSERT INTO dept VALUES (1, 'eng'), (2, 'ops'), (3, 'hr');
INSERT INTO emp VALUES (1, 'Ava', 1, 5000), (2, 'Bo', 1, 4200), (3, 'Cal', 2, 3900), (4, 'Dia', 2, 4100),
  (5, 'Eko', NULL, 3000);
INSERT INTO bonus VALUES (1, 1, 300), (1, 2, 200), (3, 1, 150), (4, 2, 400);
INSERT INTO dept (dname) VALUES (NULL);
-- department sizes and payroll, empty departments included
SELECT dname, count(eid), coalesce(sum(salary), 0) FROM dept LEFT JOIN emp USING (did) GROUP BY did ORDER BY did;
-- employees earning above their department's average
SELECT name FROM emp e WHERE salary > (SELECT avg(salary) FROM emp WHERE did = e.did) ORDER BY name;
-- department averages as a derived table
SELECT dname, a FROM dept JOIN (SELECT did, avg(salary) AS a FROM emp GROUP BY did) AS av USING (did) ORDER BY a DESC;
-- employees with no department
SELECT name FROM emp LEFT JOIN dept USING (did) WHERE dname IS NULL ORDER BY name;
-- yearly cost per employee: salary times 12 plus bonuses
SELECT name, salary * 12 + coalesce(b.total, 0) AS cost FROM emp
  LEFT JOIN (SELECT eid, sum(amount) AS total FROM bonus GROUP BY eid) b USING (eid) ORDER BY cost DESC;
-- best paid per department via a correlated scalar subquery
SELECT dname, (SELECT name FROM emp WHERE emp.did = dept.did ORDER BY salary DESC LIMIT 1) FROM dept ORDER BY dname;
-- months in which somebody in ops got a bonus
SELECT DISTINCT month FROM bonus WHERE eid IN (SELECT eid FROM emp JOIN dept USING (did) WHERE dname = 'ops')
  ORDER BY month;
-- raise for everyone below the overall average
UPDATE emp SET salary = salary + 100 WHERE salary < (SELECT avg(salary) FROM emp WHERE did IS NOT NULL);
SELECT name, salary FROM emp ORDER BY eid;
SELECT did FROM emp JOIN dept ON emp.did = dept.did;
SELECT d.* FROM dept d WHERE d.did NOT IN (SELECT did FROM emp WHERE did IS NOT NULL);
SELECT name, (SELECT did, dname FROM dept WHERE dept.did = emp.did) FROM emp;
SELECT name, b.month FROM emp JOIN bonus b USING (eid) WHERE b.amount >= 300 ORDER BY name;
