-- a compound select inside a correlated subquery
CREATE TABLE dept (id INTEGER, name TEXT);
CREATE TABLE emp (dept_id INTEGER, ename TEXT);
CREATE TABLE contractor (dept_id INTEGER, cname TEXT);
INSERT INTO dept VALUES (1, 'eng'), (2, 'ops'), (3, 'law');
INSERT INTO emp VALUES (1, 'ann'), (1, 'bob'), (2, 'cy');
INSERT INTO contractor VALUES (1, 'dan'), (3, 'eve'), (3, 'ann');
SELECT d.name, (SELECT count(*) FROM (SELECT ename FROM emp WHERE dept_id = d.id UNION SELECT cname FROM contractor WHERE dept_id = d.id)) FROM dept d ORDER BY d.name;
SELECT name FROM dept d WHERE NOT EXISTS (SELECT ename FROM emp WHERE dept_id = d.id INTERSECT SELECT 'ann') ORDER BY name;
SELECT d.name, (SELECT x FROM (SELECT ename AS x FROM emp WHERE dept_id = d.id UNION ALL SELECT cname FROM contractor WHERE dept_id = d.id) ORDER BY x LIMIT 1) FROM dept d ORDER BY d.id;
SELECT ename FROM emp WHERE ename IN (SELECT cname FROM contractor EXCEPT SELECT 'zzz');
