-- ceil takes exactly one argument; the message spells the name as written
SELECT ceil();
SELECT ceil(1.5, 2);
SELECT CEILING();
SELECT Ceiling(1, 2, 3);
SELECT ceil(2.5);
CREATE TABLE r (v REAL);
INSERT INTO r VALUES (ceil(0.1)), (ceil(-3.9));
SELECT v FROM r ORDER BY v;
