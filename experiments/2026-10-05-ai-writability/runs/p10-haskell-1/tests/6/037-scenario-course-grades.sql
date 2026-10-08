-- scenario: course grades with class ranks, quartiles and curves
CREATE TABLE student (id INTEGER PRIMARY KEY, name TEXT NOT NULL, cohort TEXT NOT NULL);
CREATE TABLE grade (student_id INTEGER, exam TEXT, mark INTEGER, UNIQUE (student_id, exam));
INSERT INTO student (name, cohort) VALUES ('ada','a'),('bea','a'),('cal','a'),('dan','b'),('eva','b'),('fin','b'),('gus','b');
INSERT INTO grade VALUES (1,'mid',78),(1,'fin',85),(2,'mid',92),(2,'fin',88),(3,'mid',65),(3,'fin',70),
  (4,'mid',78),(4,'fin',90),(5,'mid',55),(5,'fin',60),(6,'mid',88),(6,'fin',88),(7,'mid',70);
INSERT INTO grade VALUES (7,'mid',75);
CREATE VIEW final AS SELECT s.name, s.cohort, g.mark FROM student AS s JOIN grade AS g ON g.student_id = s.id WHERE g.exam = 'fin';
SELECT name, mark, rank() OVER (ORDER BY mark DESC) FROM final ORDER BY mark DESC, name;
SELECT name, cohort, mark, dense_rank() OVER (PARTITION BY cohort ORDER BY mark DESC) FROM final ORDER BY cohort, mark DESC, name;
SELECT name, ntile(4) OVER (ORDER BY mark DESC, name) AS quartile FROM final ORDER BY quartile, name;
SELECT name, round(100 * percent_rank() OVER (ORDER BY mark), 1) AS pctl FROM final ORDER BY pctl, name;
-- improvement from mid to final
SELECT s.name, g.exam, g.mark, g.mark - lag(g.mark) OVER (PARTITION BY g.student_id ORDER BY g.exam DESC) AS gain
  FROM grade AS g JOIN student AS s ON s.id = g.student_id ORDER BY s.name, g.exam DESC;
-- each cohort's average next to each mark
SELECT cohort, name, mark, round(avg(mark) OVER (PARTITION BY cohort), 2) AS cavg FROM final ORDER BY cohort, name;
SELECT cohort, name FROM final WHERE mark > 80 ORDER BY cohort, name;
-- students above their cohort's average
SELECT name FROM (SELECT name, mark, avg(mark) OVER (PARTITION BY cohort) AS a FROM final) WHERE mark > a ORDER BY name;
-- a curve: add 5 to everyone below 75 in the final
UPDATE grade SET mark = mark + 5 WHERE exam = 'fin' AND mark < 75;
SELECT name, mark, rank() OVER (ORDER BY mark) FROM final ORDER BY mark, name;
SELECT exam, count(*), min(mark), max(mark), group_concat(max(mark), '/') OVER (ORDER BY exam) FROM grade GROUP BY exam ORDER BY exam;
-- top student per exam
SELECT exam, name, mark FROM (SELECT g.exam, s.name, g.mark, rank() OVER (PARTITION BY g.exam ORDER BY g.mark DESC) AS r
  FROM grade AS g JOIN student AS s ON s.id = g.student_id) WHERE r = 1 ORDER BY exam, name;
SELECT name, cume_dist() OVER (ORDER BY mark) FROM final WHERE cohort = 'a' ORDER BY name;
SELECT cohort, count(*), sum(mark), rank() OVER (ORDER BY avg(mark) DESC) FROM final GROUP BY cohort ORDER BY cohort;
SELECT name, nth_value(name, 2) OVER (ORDER BY mark DESC, name ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) FROM final WHERE cohort = 'b' ORDER BY name;
