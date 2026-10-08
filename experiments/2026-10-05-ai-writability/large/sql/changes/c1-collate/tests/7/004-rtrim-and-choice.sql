-- RTRIM ignores trailing spaces; the left operand's collation is used before the right one's.
CREATE TABLE codes (id INTEGER, c TEXT COLLATE RTRIM, n TEXT COLLATE NOCASE, b TEXT);
INSERT INTO codes VALUES (1, 'ab  ', 'AB', 'ab'), (2, ' ab', 'ab ', 'AB'), (3, 'ab', 'Ab', 'ab ');
SELECT id FROM codes WHERE c = 'ab' ORDER BY id;
SELECT id FROM codes WHERE c = b ORDER BY id;
SELECT id FROM codes WHERE b = c ORDER BY id;
SELECT id FROM codes WHERE n = c ORDER BY id;
SELECT id FROM codes WHERE c = n ORDER BY id;
SELECT id FROM codes WHERE b = n COLLATE RTRIM ORDER BY id;
SELECT id FROM codes WHERE n COLLATE BINARY = b COLLATE NOCASE ORDER BY id;
SELECT 'ab' COLLATE RTRIM = 'ab   ', 'ab' COLLATE RTRIM < 'ab c', '' COLLATE RTRIM = '  ';
SELECT id FROM codes WHERE +n = 'ab' ORDER BY id;
SELECT id FROM codes WHERE n || '' = 'ab' ORDER BY id;
SELECT id FROM codes WHERE c = 1;
