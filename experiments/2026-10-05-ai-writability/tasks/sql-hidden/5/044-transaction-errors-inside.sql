-- failed statements inside a transaction leave it open and change nothing
CREATE TABLE item (id INTEGER PRIMARY KEY, name TEXT NOT NULL, price INTEGER);
BEGIN;
INSERT INTO item (name, price) VALUES ('pen', 2);
INSERT INTO item (name, price) VALUES ('cup', 'cheap');
CREATE TABLE item (x INTEGER);
DROP VIEW item;
INSERT INTO item (name, price) SELECT 'mug', 4 UNION ALL SELECT NULL, 1;
UPDATE item SET price = price * 10;
ALTER TABLE item ADD COLUMN sku TEXT UNIQUE;
COMMIT;
SELECT id, name, price FROM item;
BEGIN;
UPDATE item SET name = NULL;
DELETE FROM item;
ROLLBACK;
SELECT count(*) FROM item;
