-- a column named twice in SET takes the last assignment
CREATE TABLE w (a INTEGER, b TEXT);
INSERT INTO w VALUES (1, 'x'), (2, 'y');
UPDATE w SET a = 10, a = 20 WHERE b = 'x';
SELECT a, b FROM w ORDER BY a;
UPDATE w SET b = 'p', a = a + 1, b = b || 'q';
SELECT a, b FROM w ORDER BY a;
