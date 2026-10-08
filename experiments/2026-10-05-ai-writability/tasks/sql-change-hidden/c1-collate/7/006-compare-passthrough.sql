-- Parentheses, unary + and CAST keep a column's collation; other expressions have none.
CREATE TABLE items (id INTEGER, nm TEXT COLLATE NOCASE);
INSERT INTO items VALUES (1, 'Lamp'), (2, 'LAMP'), (3, 'desk');
SELECT id FROM items WHERE (nm) = 'lamp' ORDER BY id;
SELECT id FROM items WHERE +nm = 'lamp' ORDER BY id;
SELECT id FROM items WHERE CAST(nm AS TEXT) = 'lamp' ORDER BY id;
SELECT id FROM items WHERE nm || '' = 'lamp' ORDER BY id;
SELECT id FROM items WHERE upper(nm) = 'Lamp' ORDER BY id;
SELECT id FROM items WHERE 'DESK' = (nm) ORDER BY id;
SELECT id FROM items WHERE substr(nm, 1, 2) = 'la' ORDER BY id;
