CREATE TABLE staff (id INTEGER PRIMARY KEY, name TEXT, dept TEXT);
INSERT INTO staff (name, dept) VALUES ('kim', 'ops'), ('lee', 'dev'), ('max', 'ops'), ('ned', 'dev'), ('ola', 'ops');
SELECT group_concat(name, ';' ORDER BY id DESC) FROM staff;
SELECT group_concat(name ORDER BY name) FROM staff WHERE dept = 'ops';
SELECT dept, group_concat(name, '/' ORDER BY id DESC) FROM staff GROUP BY dept ORDER BY dept;
SELECT group_concat(id ORDER BY dept, name DESC) FROM staff;
