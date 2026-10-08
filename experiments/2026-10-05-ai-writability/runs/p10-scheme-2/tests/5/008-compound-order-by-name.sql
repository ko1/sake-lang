-- ORDER BY of a compound may name an alias or a column of the first simple-select
CREATE TABLE emp (ename TEXT, dept TEXT);
CREATE TABLE con (cname TEXT, firm TEXT);
INSERT INTO emp VALUES ('zoe', 'ops'), ('al', 'dev');
INSERT INTO con VALUES ('max', 'acme'), ('bea', 'init');
SELECT ename AS person, dept AS unit FROM emp UNION ALL SELECT cname, firm FROM con ORDER BY person;
SELECT ename AS person, dept AS unit FROM emp UNION ALL SELECT cname, firm FROM con ORDER BY unit DESC;
SELECT ename, dept FROM emp UNION SELECT cname, firm FROM con ORDER BY dept, ename;
SELECT ename AS who FROM emp UNION SELECT cname FROM con ORDER BY who DESC LIMIT 2;
