-- concat over table columns, in WHERE and ORDER BY; its result has no affinity
CREATE TABLE people (id INTEGER, fname TEXT, lname TEXT, age INTEGER);
INSERT INTO people VALUES (1, 'Ada', 'Lovelace', 36), (2, 'Alan', NULL, 41), (3, NULL, 'Hopper', 85);
SELECT id, concat(fname, '.', lname) FROM people ORDER BY id;
SELECT id, concat(lname, fname) AS k FROM people ORDER BY k;
SELECT id FROM people WHERE concat(fname, lname) LIKE '%e%' ORDER BY id;
SELECT concat(age, 'y') FROM people WHERE id = 1;
SELECT concat(3, 6) = 36, concat(3, 6) = '36';
SELECT id FROM people WHERE age = concat(3, 6);
SELECT concat();
