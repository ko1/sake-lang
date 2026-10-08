-- Employees assigned to projects, with hours logged.
CREATE TABLE emp (eid INTEGER PRIMARY KEY, ename TEXT, rate INTEGER, mgr INTEGER);
CREATE TABLE proj (pid INTEGER PRIMARY KEY, pname TEXT UNIQUE, budget INTEGER);
CREATE TABLE hours (eid INTEGER, pid INTEGER, h INTEGER);
INSERT INTO emp VALUES (1, 'Kay', 100, NULL), (2, 'Lee', 60, 1), (3, 'Mo', 50, 1), (4, 'Nia', 40, 2);
INSERT INTO proj VALUES (1, 'alpha', 5000), (2, 'beta', 800), (3, 'gamma', 10000);
INSERT INTO hours VALUES (2, 1, 10), (3, 1, 20), (2, 2, 5), (4, 2, 15), (1, 1, 2), (4, 2, 3);
-- cost per project vs budget
SELECT pname, sum(h * rate) AS cost, budget FROM proj LEFT JOIN hours USING (pid) LEFT JOIN emp USING (eid)
  GROUP BY pname ORDER BY pname;
-- projects over budget
SELECT pname FROM proj p WHERE budget < (SELECT sum(h * rate) FROM hours JOIN emp USING (eid) WHERE hours.pid = p.pid);
-- each employee with manager name
SELECT e.ename, m.ename AS boss FROM emp e LEFT JOIN emp m ON m.eid = e.mgr ORDER BY e.eid;
-- people who worked on every project that has hours (no project they skipped)
SELECT ename FROM emp e WHERE NOT EXISTS (SELECT 1 FROM proj p WHERE p.pid IN (SELECT pid FROM hours)
  AND NOT EXISTS (SELECT 1 FROM hours x WHERE x.pid = p.pid AND x.eid = e.eid)) ORDER BY ename;
-- hours of each employee on each project, as a grid
SELECT ename, pname, coalesce((SELECT sum(h) FROM hours WHERE hours.eid = emp.eid AND hours.pid = proj.pid), 0)
  FROM emp CROSS JOIN proj WHERE pname <> 'gamma' ORDER BY ename, pname;
-- staff reporting (directly) to someone earning more than 50
SELECT ename FROM emp WHERE mgr IN (SELECT eid FROM emp WHERE rate > 50) ORDER BY ename;
-- a raise for everyone on beta
UPDATE emp SET rate = rate + 5 WHERE eid IN (SELECT eid FROM hours JOIN proj USING (pid) WHERE pname = 'beta');
SELECT ename, rate FROM emp ORDER BY eid;
INSERT INTO proj (pname, budget) VALUES ((SELECT pname FROM proj WHERE pid = 2), 1);
SELECT pname FROM proj JOIN hours USING (pid) JOIN emp USING (pid);
SELECT ename FROM emp JOIN hours USING (eid) JOIN proj USING (pid) WHERE pid = 2 AND h > 4 ORDER BY ename;
SELECT eid FROM emp JOIN hours USING (eid) WHERE h = (SELECT max(h) FROM hours);
SELECT pid, eid FROM hours JOIN emp ON emp.eid = hours.eid;
SELECT pname, count(DISTINCT eid) FROM proj LEFT JOIN hours USING (pid) GROUP BY pname ORDER BY pname;
DELETE FROM hours WHERE pid NOT IN (SELECT pid FROM proj WHERE budget > 1000);
SELECT count(*) FROM hours;
