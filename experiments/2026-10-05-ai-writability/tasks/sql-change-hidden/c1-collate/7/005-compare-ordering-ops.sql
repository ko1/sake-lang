-- <, <=, >, >= and != under NOCASE and RTRIM; numbers and NULL are not affected.
CREATE TABLE v (id INTEGER, w TEXT COLLATE NOCASE, p TEXT COLLATE RTRIM);
INSERT INTO v VALUES (1, 'Zoo', 'm  '), (2, 'apple', 'm'), (3, '[x]', 'm!'), (4, 'MID', ' m'), (5, NULL, NULL);
SELECT id FROM v WHERE w > 'b' ORDER BY id;
SELECT id FROM v WHERE w <= 'mid' ORDER BY id;
SELECT id FROM v WHERE w COLLATE BINARY > 'b' ORDER BY id;
SELECT id FROM v WHERE p <= 'm' ORDER BY id;
SELECT id FROM v WHERE p != 'm' ORDER BY id;
SELECT id FROM v WHERE p >= 'm' ORDER BY id;
SELECT '[' COLLATE NOCASE < 'a', '[' < 'a', '[' COLLATE NOCASE < 'A', 10 COLLATE NOCASE < 9;
