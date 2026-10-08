-- Table aliases with and without AS, referenced in any letter case.
CREATE TABLE inventory (sku TEXT, qty INTEGER);
CREATE TABLE prices (sku TEXT, cents INTEGER);
INSERT INTO inventory VALUES ('ab', 3), ('cd', 0), ('ef', 12);
INSERT INTO prices VALUES ('ab', 250), ('ef', 99), ('gh', 10);
SELECT Inv.sku, P.cents * inv.qty FROM inventory inv JOIN prices AS p ON p.SKU = INV.sku ORDER BY inv.SKU;
SELECT inv.* FROM inventory AS inv WHERE inv.qty > 0 ORDER BY inv.qty DESC;
SELECT q.sku FROM inventory q LEFT JOIN prices r ON r.sku = q.sku WHERE r.cents IS NULL;
SELECT "inv".qty FROM inventory inv WHERE inv.sku = 'cd';
SELECT INV.*, p.* FROM inventory inv, prices p WHERE inv.sku = p.sku AND p.cents < 100;
