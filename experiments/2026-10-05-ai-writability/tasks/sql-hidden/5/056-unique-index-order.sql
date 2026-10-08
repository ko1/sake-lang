-- a later UNIQUE index is checked before earlier ones and before the table's own constraints
CREATE TABLE k (a INTEGER PRIMARY KEY, b TEXT UNIQUE, c TEXT, d TEXT, UNIQUE (c, d));
INSERT INTO k VALUES (1, 'b1', 'c1', 'd1');
CREATE UNIQUE INDEX k_d ON k (d);
CREATE UNIQUE INDEX k_bc ON k (b, c);
INSERT INTO k VALUES (2, 'b1', 'c1', 'd1');
INSERT INTO k VALUES (2, 'b2', 'c1', 'd1');
INSERT INTO k VALUES (2, 'b1', 'c2', 'd2');
INSERT INTO k VALUES (1, 'b1', 'c1', 'd1');
INSERT INTO k VALUES (2, 'b2', 'c2', 'd2');
INSERT INTO k VALUES (3, 'b3', 'c2', 'd3');
INSERT INTO k VALUES (NULL, 'b3', 'c2', 'd3');
SELECT a, b, c, d FROM k ORDER BY a;
