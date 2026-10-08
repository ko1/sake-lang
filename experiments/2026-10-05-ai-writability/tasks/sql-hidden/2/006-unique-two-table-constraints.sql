-- each table constraint reports its own columns; later ones are checked first
CREATE TABLE r (a INTEGER, b INTEGER, c INTEGER, UNIQUE (a, b), UNIQUE (b, c));
INSERT INTO r VALUES (1, 2, 3);
INSERT INTO r VALUES (1, 2, 3);
INSERT INTO r VALUES (1, 2, 4);
INSERT INTO r VALUES (9, 2, 3);
INSERT INTO r VALUES (9, 2, 4);
SELECT a, b, c FROM r ORDER BY a;
