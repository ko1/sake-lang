-- sqrt is the REAL square root; a negative argument gives NULL
SELECT sqrt(16), sqrt(2), sqrt(0), sqrt(0.25), typeof(sqrt(4));
SELECT sqrt(-1), sqrt(-0.01), sqrt(NULL), sqrt('81'), sqrt(' 2.25 '), sqrt('9 apples');
SELECT sqrt();
SELECT SQRT(4, 9);
CREATE TABLE pt (name TEXT, x INTEGER, y INTEGER);
INSERT INTO pt VALUES ('a', 3, 4), ('b', 5, 12), ('c', 1, 1), ('d', 0, 0);
SELECT name, sqrt(x * x + y * y) FROM pt ORDER BY name;
SELECT name FROM pt WHERE sqrt(x * x + y * y) > 4 ORDER BY sqrt(x * x + y * y) DESC;
