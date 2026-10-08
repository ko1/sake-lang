-- PARTITION BY restarts the numbering in each partition
CREATE TABLE emp (id INTEGER PRIMARY KEY, dept TEXT, name TEXT, salary INTEGER);
INSERT INTO emp (dept, name, salary) VALUES
  ('eng', 'ann', 120), ('eng', 'bob', 100), ('ops', 'cid', 90),
  ('eng', 'dee', 110), ('ops', 'eve', 95), ('hr', 'fay', 70);
SELECT dept, name, row_number() OVER (PARTITION BY dept ORDER BY salary DESC) FROM emp ORDER BY dept, salary DESC;
SELECT name, row_number() OVER (PARTITION BY dept ORDER BY id) AS n FROM emp ORDER BY id;
SELECT name, row_number() OVER (PARTITION BY salary > 100 ORDER BY name) FROM emp ORDER BY name;
SELECT name, row_number() OVER (PARTITION BY dept, salary >= 100 ORDER BY salary) FROM emp ORDER BY name;
