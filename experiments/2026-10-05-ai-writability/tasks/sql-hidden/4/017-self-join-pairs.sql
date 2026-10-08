CREATE TABLE people (pid INTEGER, name TEXT, city TEXT, age INTEGER);
INSERT INTO people VALUES (1, 'ann', 'oslo', 30), (2, 'bo', 'rome', 25), (3, 'cy', 'oslo', 41),
  (4, 'di', 'oslo', 30), (5, 'ed', 'lima', 19);
SELECT a.name, b.name FROM people a JOIN people b ON a.city = b.city AND a.pid < b.pid ORDER BY a.pid, b.pid;
SELECT a.name, count(b.pid) FROM people a LEFT JOIN people b ON b.age > a.age GROUP BY a.pid ORDER BY a.pid;
SELECT a.name, b.name FROM people a, people b WHERE a.age = b.age AND a.name <> b.name ORDER BY 1;
SELECT a.name, b.name, c.name FROM people a JOIN people b ON b.city = a.city AND b.pid > a.pid
  JOIN people c ON c.city = a.city AND c.pid > b.pid;
