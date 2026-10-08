-- scenario: course prerequisites; a student's plan checked with recursive ctes
CREATE TABLE course (code TEXT PRIMARY KEY, credits INTEGER NOT NULL);
CREATE TABLE prereq (course TEXT, needs TEXT, UNIQUE (course, needs));
CREATE TABLE passed (student TEXT, code TEXT, UNIQUE (student, code));
INSERT INTO course VALUES ('c101', 4), ('c102', 4), ('c201', 3), ('c202', 3), ('c301', 5);
INSERT INTO prereq VALUES ('c102', 'c101'), ('c201', 'c102'), ('c202', 'c101'), ('c301', 'c201'), ('c301', 'c202');
INSERT INTO passed VALUES ('kim', 'c101'), ('kim', 'c102'), ('lou', 'c101'), ('lou', 'c202');
WITH RECURSIVE req(code) AS (SELECT needs FROM prereq WHERE course = 'c301' UNION SELECT p.needs FROM prereq p JOIN req r ON p.course = r.code)
SELECT code FROM req ORDER BY code;
WITH RECURSIVE req(code) AS (SELECT needs FROM prereq WHERE course = 'c301' UNION SELECT p.needs FROM prereq p JOIN req r ON p.course = r.code)
SELECT code FROM req EXCEPT SELECT code FROM passed WHERE student = 'kim' ORDER BY code;
WITH RECURSIVE req(code) AS (SELECT needs FROM prereq WHERE course = 'c301' UNION SELECT p.needs FROM prereq p JOIN req r ON p.course = r.code)
SELECT sum(credits) FROM course WHERE code IN (SELECT code FROM req);
CREATE VIEW eligible AS SELECT s.student, c.code FROM (SELECT DISTINCT student FROM passed) s, course c
 WHERE NOT EXISTS (SELECT 1 FROM prereq p WHERE p.course = c.code AND p.needs NOT IN (SELECT code FROM passed x WHERE x.student = s.student))
 AND c.code NOT IN (SELECT code FROM passed y WHERE y.student = s.student);
SELECT student, code FROM eligible ORDER BY student, code;
INSERT INTO passed SELECT student, code FROM eligible WHERE code = 'c201';
INSERT INTO passed VALUES ('kim', 'c101');
SELECT student, code FROM eligible ORDER BY student, code;
SELECT student, sum(c.credits) FROM passed p JOIN course c USING (code) GROUP BY student ORDER BY student;
INSERT INTO passed SELECT 'kim', code FROM eligible WHERE student = 'kim' UNION ALL SELECT 'kim', 'c202';
SELECT count(*) FROM passed WHERE student = 'kim';
DELETE FROM eligible;
DROP VIEW eligible;
SELECT count(*) FROM eligible;
