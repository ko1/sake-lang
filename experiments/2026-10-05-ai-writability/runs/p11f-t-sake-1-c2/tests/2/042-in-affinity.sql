-- x IN (...) compares like x = e, with the affinity of the column x
CREATE TABLE p (zip TEXT, n INTEGER);
INSERT INTO p VALUES ('02134', 2134), ('10001', 10001), ('7', 7);
SELECT zip FROM p WHERE zip IN (7, 10001) ORDER BY n;
SELECT zip FROM p WHERE n IN ('7', '02134') ORDER BY n;
SELECT n FROM p WHERE n IN (' 7 ', 'seven') ORDER BY n;
SELECT zip FROM p WHERE zip IN (2134) ORDER BY n;
SELECT 7 IN ('7'), '7' IN (7);
