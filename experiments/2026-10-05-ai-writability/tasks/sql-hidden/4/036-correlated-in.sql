-- IN with a correlated subquery is evaluated per row.
CREATE TABLE courses (cid TEXT, dept TEXT);
CREATE TABLE prereq (cid TEXT, needs TEXT);
CREATE TABLE passed (student TEXT, cid TEXT);
INSERT INTO courses VALUES ('m1', 'math'), ('m2', 'math'), ('p1', 'phys'), ('p2', 'phys');
INSERT INTO prereq VALUES ('m2', 'm1'), ('p2', 'p1'), ('p2', 'm1');
INSERT INTO passed VALUES ('ann', 'm1'), ('ann', 'p1'), ('bob', 'm1'), ('cy', 'p1');
SELECT student, cid FROM passed p WHERE cid IN (SELECT cid FROM courses WHERE dept = 'math') ORDER BY student;
SELECT DISTINCT p.student, c.cid FROM passed p, courses c WHERE c.cid NOT IN (SELECT cid FROM passed WHERE student = p.student)
  AND NOT EXISTS (SELECT 1 FROM prereq r WHERE r.cid = c.cid
    AND r.needs NOT IN (SELECT cid FROM passed WHERE student = p.student)) ORDER BY p.student, c.cid;
SELECT cid, (SELECT count(*) FROM passed WHERE passed.cid IN (SELECT needs FROM prereq WHERE prereq.cid = courses.cid))
  FROM courses ORDER BY cid;
