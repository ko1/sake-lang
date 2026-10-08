-- INTERSECT compares whole rows
CREATE TABLE plan (day INTEGER, task TEXT);
CREATE TABLE done (day INTEGER, task TEXT);
INSERT INTO plan VALUES (1, 'wash'), (1, 'cook'), (2, 'shop'), (3, 'read'), (3, 'read');
INSERT INTO done VALUES (1, 'cook'), (2, 'wash'), (3, 'read'), (3, 'READ');
SELECT day, task FROM plan INTERSECT SELECT day, task FROM done ORDER BY day;
SELECT task FROM plan INTERSECT SELECT task FROM done ORDER BY task;
SELECT day FROM plan INTERSECT SELECT day FROM done INTERSECT SELECT 2 + 1;
SELECT count(*) FROM (SELECT day, task FROM plan INTERSECT SELECT day, upper(task) FROM done);
