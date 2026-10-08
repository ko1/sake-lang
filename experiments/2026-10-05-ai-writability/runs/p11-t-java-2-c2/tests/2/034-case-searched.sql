CREATE TABLE sc (name TEXT, score INTEGER);
INSERT INTO sc VALUES ('a', 95), ('b', 82), ('c', 67), ('d', NULL), ('e', 40);
SELECT name, CASE WHEN score >= 90 THEN 'A' WHEN score >= 80 THEN 'B' WHEN score >= 60 THEN 'C' ELSE 'F' END FROM sc ORDER BY name;
SELECT name, CASE WHEN score > 50 THEN 'pass' END FROM sc ORDER BY name;
SELECT CASE WHEN NULL THEN 1 WHEN 'abc' THEN 2 WHEN '0.0' THEN 3 WHEN '2x' THEN 4 END;
SELECT CASE WHEN 0 THEN 'no' ELSE 'else' END, CASE WHEN 1 THEN 'first' WHEN 1 THEN 'second' END;
