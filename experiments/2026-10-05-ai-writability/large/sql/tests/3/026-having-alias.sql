CREATE TABLE marks (student TEXT, mark INTEGER);
INSERT INTO marks VALUES ('ann', 70), ('ann', 90), ('ben', 40), ('ben', 60), ('cat', 85);
SELECT student, avg(mark) AS m FROM marks GROUP BY student HAVING m >= 80 ORDER BY student;
SELECT student AS s, count(*) AS c FROM marks GROUP BY s HAVING c > 1 AND s < 'b' ORDER BY s;
SELECT student, max(mark) - min(mark) AS spread FROM marks GROUP BY student HAVING spread > 0 ORDER BY spread DESC, student;
