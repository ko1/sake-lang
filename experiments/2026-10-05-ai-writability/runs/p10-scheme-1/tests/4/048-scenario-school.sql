-- Students, courses and enrollments with grades.
CREATE TABLE students (id INTEGER PRIMARY KEY, name TEXT NOT NULL, year INTEGER DEFAULT 1);
CREATE TABLE courses (code TEXT PRIMARY KEY, title TEXT, credits INTEGER);
CREATE TABLE enrolled (student_id INTEGER, code TEXT, grade REAL, UNIQUE (student_id, code));
INSERT INTO students (name, year) VALUES ('Ana', 2), ('Ben', 1), ('Cy', 3), ('Dot', 1);
INSERT INTO students (name) VALUES ('Eli');
INSERT INTO courses VALUES ('M1', 'Algebra', 5), ('P1', 'Physics', 4), ('H1', 'History', 3), ('A1', 'Art', 2);
INSERT INTO enrolled VALUES (1, 'M1', 3.5), (1, 'P1', 4.0), (2, 'M1', 2.0), (3, 'H1', 3.0), (3, 'M1', NULL);
INSERT INTO enrolled VALUES (4, 'P1', 3.0), (4, 'H1', 2.5);
INSERT INTO enrolled VALUES (2, 'H1', 1.0), (2, 'M1', 4.0);
-- roster per course, empty courses included
SELECT title, name FROM courses c LEFT JOIN enrolled e USING (code) LEFT JOIN students s ON s.id = e.student_id
  ORDER BY title, name;
-- credit-weighted average for each student with at least one grade
SELECT name, round(sum(grade * credits) / sum(credits), 2) AS gpa FROM students
  JOIN enrolled ON student_id = students.id JOIN courses USING (code)
  WHERE grade IS NOT NULL GROUP BY students.id ORDER BY gpa DESC, name;
-- students not enrolled anywhere
SELECT name FROM students WHERE NOT EXISTS (SELECT 1 FROM enrolled WHERE student_id = students.id) ORDER BY name;
-- students above the overall average grade in some course
SELECT DISTINCT name FROM students JOIN enrolled ON student_id = id
  WHERE grade > (SELECT avg(grade) FROM enrolled) ORDER BY name;
-- credits taken per year group
SELECT year, sum(credits) FROM students JOIN enrolled ON student_id = id JOIN courses USING (code)
  GROUP BY year ORDER BY year;
-- course with the most students
SELECT title FROM courses WHERE code = (SELECT code FROM enrolled GROUP BY code ORDER BY count(*) DESC LIMIT 1);
-- grade missing: give it the course average
UPDATE enrolled SET grade = (SELECT avg(grade) FROM enrolled WHERE code = 'M1') WHERE grade IS NULL AND code = 'M1';
SELECT name, grade FROM enrolled JOIN students ON id = student_id WHERE code = 'M1' ORDER BY name;
SELECT name, code FROM students JOIN enrolled ON id = student_id JOIN courses USING (code) WHERE credits > 4
  ORDER BY name;
SELECT code FROM enrolled JOIN courses ON enrolled.code = courses.code;
SELECT s.* FROM students s WHERE s.year = (SELECT max(year) FROM students);
SELECT name, (SELECT count(*) FROM enrolled WHERE student_id = s.id) FROM students s ORDER BY 2 DESC, 1;
