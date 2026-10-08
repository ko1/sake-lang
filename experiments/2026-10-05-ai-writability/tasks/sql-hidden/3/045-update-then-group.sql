CREATE TABLE items (id INTEGER PRIMARY KEY, cat TEXT, price INTEGER);
INSERT INTO items (cat, price) VALUES ('toy', 5), ('toy', 12), ('book', 8), ('book', 20), ('food', 3);
UPDATE items SET cat = CASE WHEN price > 10 THEN 'premium' ELSE cat END;
SELECT cat, count(*), sum(price) FROM items GROUP BY cat ORDER BY cat;
UPDATE items SET price = price + 1, cat = upper(cat) WHERE cat <> 'premium';
SELECT cat, group_concat(price, ',' ORDER BY price) FROM items GROUP BY cat ORDER BY cat;
UPDATE items SET price = 2.5 WHERE id = 5;
DELETE FROM items WHERE cat = 'premium';
SELECT count(*), sum(price), max(cat) FROM items;
