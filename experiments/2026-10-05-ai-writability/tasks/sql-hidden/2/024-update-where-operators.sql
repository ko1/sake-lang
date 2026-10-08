CREATE TABLE emp (name TEXT, dept TEXT, pay INTEGER);
INSERT INTO emp VALUES ('Ava', 'ops', 50), ('Bo', 'dev', 70), ('Cid', 'dev', 90), ('Dot', 'qa', 60), ('Eve', NULL, 80);
UPDATE emp SET pay = pay + 5 WHERE dept IN ('ops', 'qa');
UPDATE emp SET pay = pay * 2 WHERE name LIKE '_o%';
UPDATE emp SET dept = 'lead' WHERE pay BETWEEN 85 AND 95;
UPDATE emp SET dept = 'misc' WHERE dept NOT IN ('dev', 'lead');
SELECT name, coalesce(dept, '-'), pay FROM emp ORDER BY name;
