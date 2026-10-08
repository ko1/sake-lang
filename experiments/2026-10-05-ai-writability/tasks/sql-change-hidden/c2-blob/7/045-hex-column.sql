CREATE TABLE codes (id INTEGER, c BLOB, t TEXT);
INSERT INTO codes VALUES (1, X'1F2E', 'ok'), (2, NULL, NULL), (3, X'', 'Z');
SELECT id, hex(c), hex(t), length(hex(c)) FROM codes ORDER BY id;
SELECT id FROM codes WHERE hex(c) = '1F2E';
SELECT hex(c, t) FROM codes;
