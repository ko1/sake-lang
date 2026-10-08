CREATE TABLE mix (id INTEGER, i INTEGER, t TEXT);
INSERT INTO mix VALUES (1, 10, '2.5'), (2, 20, 'abc'), (3, NULL, '1.5x'), (4, 5, NULL);
SELECT sum(i), sum(CASE WHEN id = 2 THEN 0.5 ELSE i END) FROM mix;
SELECT typeof(sum(CASE WHEN id = 2 THEN 0.5 ELSE i END)) FROM mix;
SELECT sum(t), typeof(sum(t)), total(t), avg(t) FROM mix;
SELECT avg(i), total(i) FROM mix;
