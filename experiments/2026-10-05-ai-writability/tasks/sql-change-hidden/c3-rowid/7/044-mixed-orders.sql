-- orders keyed by an INTEGER PRIMARY KEY, lines referring to it, a view summing them
CREATE TABLE orders (ono INTEGER PRIMARY KEY, who TEXT);
CREATE TABLE line (ono INTEGER, item TEXT, price INTEGER);
INSERT INTO orders (who) VALUES ('ann'), ('bob');
INSERT INTO line VALUES (1, 'pen', 3), (2, 'ink', 7), (1, 'pad', 4);
CREATE VIEW order_total AS SELECT o.rowid AS ono, who, sum(price) AS total FROM orders AS o JOIN line ON line.ono = o.rowid GROUP BY o.rowid;
SELECT * FROM order_total ORDER BY ono;
UPDATE orders SET rowid = 10 WHERE who = 'ann';
UPDATE line SET ono = 10 WHERE ono = 1;
SELECT ono, who, total FROM order_total ORDER BY total DESC, ono;
SELECT o.ono, count(line.rowid) FROM orders AS o LEFT JOIN line USING (ono) GROUP BY o.ono ORDER BY 1;
