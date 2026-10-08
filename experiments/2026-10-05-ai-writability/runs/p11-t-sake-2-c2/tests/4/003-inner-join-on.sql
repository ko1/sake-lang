CREATE TABLE dept (id INTEGER PRIMARY KEY, name TEXT);
CREATE TABLE emp (id INTEGER PRIMARY KEY, name TEXT, dept_id INTEGER);
INSERT INTO dept VALUES (1, 'Sales'), (2, 'Ops'), (3, 'Legal');
INSERT INTO emp VALUES (1, 'Ann', 1), (2, 'Bob', 2), (3, 'Cid', 1), (4, 'Dee', NULL), (5, 'Eve', 9);
SELECT emp.name, dept.name FROM emp JOIN dept ON emp.dept_id = dept.id ORDER BY emp.name;
SELECT emp.name FROM emp INNER JOIN dept ON dept.id = emp.dept_id WHERE dept.name = 'Sales' ORDER BY 1;
SELECT count(*) FROM dept JOIN emp ON emp.dept_id = dept.id;
