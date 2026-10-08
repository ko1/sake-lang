-- an UPDATE that fails on some row changes no row
CREATE TABLE s (id INTEGER, code TEXT UNIQUE, qty INTEGER NOT NULL);
INSERT INTO s VALUES (1, 'a', 5), (2, 'b', 0), (3, 'c', 7);
UPDATE s SET qty = nullif(qty, 0);
SELECT id, qty FROM s ORDER BY id;
UPDATE s SET code = 'z';
SELECT id, code FROM s ORDER BY id;
UPDATE s SET qty = CASE WHEN id = 3 THEN 'x' ELSE qty + 1 END;
SELECT id, qty FROM s ORDER BY id;
UPDATE s SET code = code || id, qty = qty + 1;
SELECT id, code, qty FROM s ORDER BY id;
