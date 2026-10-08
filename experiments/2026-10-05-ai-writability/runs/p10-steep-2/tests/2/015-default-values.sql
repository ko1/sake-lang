CREATE TABLE orders (id INTEGER, status TEXT DEFAULT 'new', qty INTEGER DEFAULT 1, discount REAL DEFAULT -0.5, note TEXT DEFAULT NULL);
INSERT INTO orders (id) VALUES (1);
INSERT INTO orders (id, qty) VALUES (2, 5);
INSERT INTO orders (id, status) VALUES (3, NULL);
INSERT INTO orders VALUES (4, 'paid', 2, 0, 'x');
SELECT id, status, qty, discount, note FROM orders ORDER BY id;
SELECT typeof(discount), typeof(note) FROM orders WHERE id = 1;
