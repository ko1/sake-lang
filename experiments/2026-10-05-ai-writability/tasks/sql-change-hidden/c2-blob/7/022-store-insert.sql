CREATE TABLE img (id INTEGER, px BLOB, note TEXT);
INSERT INTO img VALUES (1, X'FF', 'a');
INSERT INTO img VALUES (2, ' 3 ', 'b');
INSERT INTO img VALUES (3, -7, 'c');
INSERT INTO img VALUES (4, 0.25, 'd');
INSERT INTO img VALUES (5, X'00', X'00');
INSERT INTO img (id, note) VALUES (6, 'no px');
SELECT id, px, note FROM img ORDER BY id;
