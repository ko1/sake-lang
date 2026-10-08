-- GLOB is case-sensitive; LIKE is not
SELECT 'abc' GLOB 'abc', 'ABC' GLOB 'abc', 'Abc' GLOB 'A*', 'abc' GLOB 'A*';
SELECT 'x' GLOB 'X', 'x' LIKE 'X', 'Hello' GLOB 'H*o', 'Hello' GLOB 'h*O', 'Hello' LIKE 'h%O';
CREATE TABLE people (id INTEGER PRIMARY KEY, name TEXT);
INSERT INTO people (name) VALUES ('Ann'), ('ann'), ('ANNA'), ('Annie'), ('Bob');
SELECT id, name FROM people WHERE name GLOB 'Ann*' ORDER BY id;
SELECT id, name FROM people WHERE name LIKE 'ann%' ORDER BY id;
SELECT id FROM people WHERE name GLOB '*n*' ORDER BY id;
SELECT count(*) FROM people WHERE name GLOB '*N*';
