CREATE TABLE stock (item TEXT NOT NULL, qty INTEGER NOT NULL, bin TEXT);
INSERT INTO stock VALUES ('a', 3, 'x1'), ('b', 0, NULL), ('c', 9, 'x2');
UPDATE stock SET item = bin;
UPDATE stock SET item = bin WHERE bin IS NOT NULL;
SELECT item, qty FROM stock ORDER BY qty;
UPDATE stock SET qty = CASE WHEN qty > 5 THEN NULL ELSE qty END WHERE item <> 'b';
SELECT item, qty FROM stock ORDER BY qty;
UPDATE stock SET bin = NULL;
SELECT item, bin IS NULL FROM stock ORDER BY item;
