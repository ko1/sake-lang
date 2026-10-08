-- Aggregates over joined rows, including the NULL-extended rows of a LEFT JOIN.
CREATE TABLE courses (id INTEGER, title TEXT);
CREATE TABLE marks (course_id INTEGER, student TEXT, mark INTEGER);
INSERT INTO courses VALUES (1, 'math'), (2, 'art'), (3, 'music');
INSERT INTO marks VALUES (1, 'ann', 80), (1, 'bob', 65), (2, 'ann', 90), (1, 'cid', NULL);
SELECT title, count(*), count(mark), sum(mark), avg(mark) FROM courses LEFT JOIN marks ON course_id = id
  GROUP BY title ORDER BY title;
SELECT title, max(mark) FROM courses JOIN marks ON course_id = id GROUP BY id HAVING count(*) > 1;
SELECT student, group_concat(title, '+' ORDER BY title) FROM marks JOIN courses ON id = course_id
  GROUP BY student ORDER BY student;
SELECT count(DISTINCT student), total(mark) FROM marks JOIN courses ON id = course_id WHERE title <> 'art';
