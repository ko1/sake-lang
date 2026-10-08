-- the uniqueness constraints are checked from the last declared to the first
CREATE TABLE u (a INTEGER UNIQUE, b TEXT UNIQUE, c INTEGER, d INTEGER, UNIQUE (c, d));
INSERT INTO u VALUES (1, 'p', 1, 1);
INSERT INTO u VALUES (1, 'p', 1, 1);
INSERT INTO u VALUES (1, 'p', 1, 2);
INSERT INTO u VALUES (1, 'q', 1, 2);
INSERT INTO u VALUES (2, 'q', 1, 2);
SELECT * FROM u ORDER BY a;
