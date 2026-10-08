-- declaration order: column constraints in column order, then table constraints
CREATE TABLE d (a INTEGER UNIQUE, b INTEGER, c INTEGER UNIQUE, UNIQUE (b));
INSERT INTO d VALUES (1, 1, 1);
INSERT INTO d VALUES (1, 1, 1);
INSERT INTO d VALUES (1, 2, 1);
INSERT INTO d VALUES (1, 2, 2);
INSERT INTO d VALUES (2, 2, 2);
SELECT a, b, c FROM d ORDER BY a;
