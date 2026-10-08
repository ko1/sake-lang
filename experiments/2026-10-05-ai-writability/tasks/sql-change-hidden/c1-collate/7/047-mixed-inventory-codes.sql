-- Inventory with padded codes (RTRIM) joined to case-varying supplier names (NOCASE).
CREATE TABLE stock (code TEXT PRIMARY KEY COLLATE RTRIM, supplier TEXT, qty INTEGER);
CREATE TABLE suppliers (name TEXT COLLATE NOCASE, city TEXT);
INSERT INTO stock VALUES ('A-1  ', 'acme', 5), ('B-2', 'Bolt Co', 0), ('C-3 ', 'ACME', 12);
INSERT INTO stock VALUES ('A-1', 'acme', 1);
INSERT INTO suppliers VALUES ('Acme', 'Oslo'), ('bolt co', 'Bergen');
SELECT s.city, sum(qty) FROM suppliers s JOIN stock ON s.name = stock.supplier GROUP BY s.city ORDER BY 1;
SELECT count(*) FROM stock JOIN suppliers ON stock.supplier = suppliers.name;
UPDATE stock SET qty = qty + 10 WHERE code = 'B-2';
SELECT rtrim(code), qty FROM stock WHERE code IN ('A-1', 'B-2') ORDER BY code;
SELECT city FROM suppliers WHERE name = (SELECT supplier FROM stock WHERE code = 'C-3');
SELECT city FROM suppliers WHERE name = (SELECT supplier FROM stock WHERE code = 'B-2');
DELETE FROM stock WHERE supplier COLLATE NOCASE = 'Acme';
SELECT count(*) FROM stock;
