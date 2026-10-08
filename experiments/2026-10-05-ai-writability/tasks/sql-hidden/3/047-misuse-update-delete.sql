CREATE TABLE inv (sku TEXT, qty INTEGER);
INSERT INTO inv VALUES ('a', 1), ('b', 5), ('c', 9);
UPDATE inv SET qty = 0 WHERE qty = min(qty);
DELETE FROM inv WHERE count(*) > 2;
DELETE FROM inv WHERE group_concat(sku) = 'a';
UPDATE inv SET qty = qty + 1 WHERE qty = max(qty, 5);
SELECT group_concat(sku || qty, ' ' ORDER BY sku) FROM inv;
