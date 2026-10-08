CREATE TABLE parts (k INTEGER, p TEXT);
INSERT INTO parts VALUES (1, 'red'), (1, 'red'), (2, 'blue');
SELECT group_concat(p, ' + ') FROM parts WHERE k = 1;
SELECT group_concat(p, '') FROM parts WHERE k = 1;
SELECT group_concat(k, 0) FROM parts WHERE k = 1;
SELECT group_concat(p, 2.5) FROM parts WHERE k = 1;
SELECT group_concat(k * 1.5, ';') FROM parts WHERE k = 2;
