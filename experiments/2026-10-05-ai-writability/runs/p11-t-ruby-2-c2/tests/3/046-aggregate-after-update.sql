CREATE TABLE stock (sku TEXT PRIMARY KEY, qty INTEGER NOT NULL DEFAULT 0);
INSERT INTO stock (sku) VALUES ('a1'), ('b2');
INSERT INTO stock VALUES ('c3', 7);
SELECT count(*), sum(qty) FROM stock;
UPDATE stock SET qty = qty + 5 WHERE sku < 'c';
SELECT sum(qty), avg(qty) FROM stock;
UPDATE stock SET qty = NULL WHERE sku = 'a1';
DELETE FROM stock WHERE qty > 6;
SELECT count(*), group_concat(sku ORDER BY sku) FROM stock;
