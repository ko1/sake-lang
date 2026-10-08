-- q.* in a join lists only the real columns of q
CREATE TABLE dept (dname TEXT);
CREATE TABLE staff (sname TEXT, dno INTEGER);
INSERT INTO dept VALUES ('ops'), ('dev');
INSERT INTO staff VALUES ('ann', 2), ('bob', 1), ('cy', 2);
SELECT d.*, s.* FROM dept AS d JOIN staff AS s ON s.dno = d.rowid ORDER BY sname;
SELECT staff.*, dept.rowid FROM staff, dept WHERE dept.rowid = staff.dno AND dname = 'dev' ORDER BY 1;
SELECT * FROM staff JOIN dept ON dno = dept.oid ORDER BY sname;
