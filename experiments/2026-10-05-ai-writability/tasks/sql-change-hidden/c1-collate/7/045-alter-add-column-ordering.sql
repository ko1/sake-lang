-- An added RTRIM column compares, sorts and groups under RTRIM.
CREATE TABLE items (id INTEGER);
INSERT INTO items VALUES (1), (2), (3);
ALTER TABLE items ADD COLUMN code TEXT COLLATE RTRIM;
UPDATE items SET code = 'k   ' WHERE id = 1;
UPDATE items SET code = 'k' WHERE id = 2;
UPDATE items SET code = 'k!' WHERE id = 3;
SELECT id FROM items WHERE code = 'k' ORDER BY id;
SELECT id FROM items ORDER BY code, id;
SELECT count(*) FROM (SELECT code FROM items GROUP BY code);
