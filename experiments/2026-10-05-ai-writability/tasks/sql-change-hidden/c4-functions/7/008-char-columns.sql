-- char over column values and expressions
CREATE TABLE codes (id INTEGER, cp INTEGER);
INSERT INTO codes VALUES (1, 83), (2, 113), (3, 108), (4, 33);
SELECT id, char(cp) FROM codes ORDER BY id;
SELECT id, char(cp, cp + 1) FROM codes WHERE cp > 100 ORDER BY id;
SELECT char(cp - 32) FROM codes WHERE id = 2;
SELECT id FROM codes WHERE char(cp) = 'l' ORDER BY id;
