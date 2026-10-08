CREATE TABLE x (k INTEGER, v TEXT, w REAL);
INSERT INTO x VALUES (1 + 1, upper('ab') || 'c', 1 / 4);
INSERT INTO x VALUES (abs(-3), coalesce(NULL, 'd'), 1.0 / 4);
INSERT INTO x VALUES ('4' * 1, typeof(1.5), -'2.5');
INSERT INTO x VALUES (5, v, 1);
INSERT INTO x VALUES (k, 'e', 1);
INSERT INTO x (k, v) VALUES (6, w);
INSERT INTO x VALUES (length('1234567'), 1 || 2, NULL);
SELECT k, v, w FROM x ORDER BY k;
