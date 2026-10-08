CREATE TABLE o (id INTEGER, qty INTEGER, unit TEXT);
INSERT INTO o VALUES (1, 4, 'box'), (2, 6, 'bag'), (3, 8, 'box'), (4, 12, 'tin');
SELECT id FROM o WHERE qty IN (2 * 2, 2 * 4, 100) ORDER BY id;
SELECT id FROM o WHERE qty % 4 IN (0) AND unit NOT IN ('tin') ORDER BY id;
SELECT id, unit IN ('BOX', 'bag') FROM o ORDER BY id;
SELECT id FROM o WHERE id + qty IN (5, 16, 99) ORDER BY id DESC;
SELECT 'x' IN ('a', 'x'), 2.0 IN (1, 2), upper('a') IN ('A');
