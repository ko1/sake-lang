-- A course catalogue with prerequisites (a table referring to itself).
CREATE TABLE course (code TEXT PRIMARY KEY, name TEXT, credits INTEGER NOT NULL);
CREATE TABLE prereq (code TEXT, req TEXT, UNIQUE (code, req));
CREATE TABLE taken (student TEXT, code TEXT, grade INTEGER);
INSERT INTO course VALUES ('C1', 'Intro', 5), ('C2', 'Data', 5), ('C3', 'Algo', 7), ('C4', 'Theory', 7), ('C5', 'Lab', 2);
INSERT INTO prereq VALUES ('C2', 'C1'), ('C3', 'C2'), ('C4', 'C3'), ('C4', 'C1');
INSERT INTO taken VALUES ('eva', 'C1', 4), ('eva', 'C2', 5), ('eva', 'C3', 3), ('finn', 'C1', 2), ('gus', 'C5', 5);
INSERT INTO prereq VALUES ('C5', 'C1'), ('C4', 'C3');
-- direct prerequisites by name
SELECT c.name, r.name FROM prereq p JOIN course c ON c.code = p.code JOIN course r ON r.code = p.req
  ORDER BY c.code, r.code;
-- prerequisites of prerequisites
SELECT p1.code, p2.req FROM prereq p1 JOIN prereq p2 ON p2.code = p1.req ORDER BY 1, 2;
-- courses with no prerequisite
SELECT code FROM course LEFT JOIN prereq USING (code) WHERE req IS NULL ORDER BY code;
-- what each student may take next: not taken, every prerequisite taken
SELECT DISTINCT s.student, c.code FROM taken s, course c
  WHERE NOT EXISTS (SELECT 1 FROM taken t WHERE t.student = s.student AND t.code = c.code)
  AND NOT EXISTS (SELECT 1 FROM prereq p WHERE p.code = c.code AND p.req NOT IN
    (SELECT code FROM taken WHERE student = s.student)) ORDER BY 1, 2;
-- credits and weighted grade per student
SELECT student, sum(credits), round(sum(grade * credits) * 1.0 / sum(credits), 2) FROM taken JOIN course USING (code)
  GROUP BY student ORDER BY student;
-- courses required by the most others
SELECT name FROM course WHERE code IN (SELECT req FROM prereq GROUP BY req HAVING count(*) =
  (SELECT max(n) FROM (SELECT count(*) AS n FROM prereq GROUP BY req)));
SELECT code, (SELECT count(*) FROM taken WHERE taken.code = course.code AND grade >= 4) FROM course ORDER BY code;
SELECT name FROM course JOIN prereq USING (code) JOIN taken USING (req);
SELECT req FROM prereq JOIN taken USING (code) WHERE student = 'eva' ORDER BY code, req;
SELECT code FROM prereq JOIN course ON course.code = prereq.req;
UPDATE taken SET grade = grade + 1 WHERE code IN (SELECT code FROM course WHERE credits = 7);
SELECT student, max(grade) FROM taken GROUP BY student ORDER BY student;
SELECT c.name FROM course c WHERE NOT EXISTS (SELECT 1 FROM taken t WHERE t.code = c.code) ORDER BY c.name;
