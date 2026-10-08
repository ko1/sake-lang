-- a failing row makes the whole INSERT insert nothing
CREATE TABLE p (sku TEXT UNIQUE, qty INTEGER NOT NULL);
INSERT INTO p VALUES ('a', 1), ('b', 2), ('a', 3);
SELECT count_rows FROM p;
SELECT 'rows:' || length(sku) FROM p;
INSERT INTO p VALUES ('c', 1), ('d', NULL);
INSERT INTO p VALUES ('e', 1), ('f', 'many');
INSERT INTO p VALUES ('g', 1), ('h', 2);
SELECT sku, qty FROM p ORDER BY sku;
