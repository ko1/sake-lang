CREATE TABLE emp (name TEXT, dept TEXT, salary INTEGER);
INSERT INTO emp VALUES ('ann', 'ops', 100), ('bob', 'dev', 120), ('cat', 'dev', 130), ('dan', 'ops', 90);
UPDATE emp SET salary = salary + 10 WHERE dept = 'dev';
SELECT name, salary FROM emp ORDER BY name;
UPDATE emp SET dept = 'mgmt', salary = salary * 2 WHERE name = 'ann';
SELECT name, dept, salary FROM emp ORDER BY name;
UPDATE emp SET salary = 0 WHERE dept = 'none';
SELECT name, dept, salary FROM emp ORDER BY salary DESC;
