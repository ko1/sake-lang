-- an INTEGER comes back unchanged; text is converted only if it is a whole numeric literal
SELECT ceil(5), typeof(ceil(5)), ceil(-12), ceiling(0);
SELECT ceil('3'), typeof(ceil('3')), ceil('3.2'), ceil(' -2.5 '), ceil('1e2'), ceil('.5');
SELECT ceil('3x'), ceil('abc'), ceil(''), ceil(NULL), typeof(ceil('abc'));
SELECT ceil(-0.5), ceil(-0.5) || '!';
CREATE TABLE m (n INTEGER, s TEXT);
INSERT INTO m VALUES (1, '4.1'), (2, 'x'), (3, '7'), (4, NULL);
SELECT n, ceil(s), typeof(ceil(s)), ceil(n) FROM m ORDER BY n;
