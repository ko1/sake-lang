CREATE TABLE grades (student TEXT, course TEXT, mark INTEGER, PRIMARY KEY (student, course));
INSERT INTO grades VALUES ('kim', 'math', 90), ('kim', 'art', 75), ('lee', 'math', 82);
INSERT INTO grades VALUES ('lee', 'math', 60);
INSERT INTO grades VALUES ('lee', NULL, 60);
INSERT INTO grades (student, mark) VALUES ('max', 70);
INSERT INTO grades VALUES ('lee', 'art', 88);
SELECT student, course, mark FROM grades ORDER BY student, course;
UPDATE grades SET course = 'math' WHERE student = 'kim' AND course = 'art';
SELECT count_marks FROM grades;
