-- each row of one INSERT sees the rows before it
CREATE TABLE ev (id INTEGER PRIMARY KEY, what TEXT);
INSERT INTO ev VALUES (NULL, 'one'), (5, 'two'), (NULL, 'three'), (NULL, 'four');
SELECT id, what FROM ev ORDER BY id;
INSERT INTO ev VALUES (NULL, 'five'), (8, 'six');
SELECT id, what FROM ev ORDER BY id;
INSERT INTO ev VALUES (-3, 'neg');
SELECT id FROM ev ORDER BY id LIMIT 2;
