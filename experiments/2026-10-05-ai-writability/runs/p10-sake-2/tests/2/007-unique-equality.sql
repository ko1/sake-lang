-- uniqueness compares values of the column: REAL 2 equals 2.0, TEXT is case-sensitive
CREATE TABLE m (r REAL UNIQUE, s TEXT UNIQUE);
INSERT INTO m VALUES (2, 'Kiwi');
INSERT INTO m VALUES (2.0, 'kiwi');
INSERT INTO m VALUES ('2', 'lime');
INSERT INTO m VALUES (3, 'kiwi');
INSERT INTO m VALUES (4, 5);
INSERT INTO m VALUES (5, '5');
INSERT INTO m VALUES (6, '5.0');
SELECT r, s FROM m ORDER BY r;
