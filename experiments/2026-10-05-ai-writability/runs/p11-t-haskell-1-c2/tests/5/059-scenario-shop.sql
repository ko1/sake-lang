-- scenario: a shop's orders, reports with ctes and compound selects
CREATE TABLE product (sku TEXT PRIMARY KEY, name TEXT, price INTEGER NOT NULL);
CREATE TABLE orders (id INTEGER PRIMARY KEY, customer TEXT, day INTEGER);
CREATE TABLE line (order_id INTEGER, sku TEXT, qty INTEGER);
INSERT INTO product VALUES ('p1', 'pen', 3), ('p2', 'pad', 5), ('p3', 'ink', 12);
INSERT INTO orders (customer, day) VALUES ('ann', 1), ('bob', 1), ('ann', 2), ('cy', 3);
INSERT INTO line VALUES (1, 'p1', 2), (1, 'p3', 1), (2, 'p2', 4), (3, 'p1', 10), (4, 'p3', 2), (4, 'p2', 1);
WITH totals AS (SELECT l.order_id, sum(l.qty * p.price) AS amount FROM line l JOIN product p ON p.sku = l.sku GROUP BY l.order_id)
SELECT o.id, o.customer, t.amount FROM orders o JOIN totals t ON t.order_id = o.id ORDER BY o.id;
WITH totals AS (SELECT l.order_id, sum(l.qty * p.price) AS amount FROM line l JOIN product p ON p.sku = l.sku GROUP BY l.order_id),
 bycust AS (SELECT o.customer, sum(t.amount) AS spent FROM orders o JOIN totals t ON t.order_id = o.id GROUP BY o.customer)
SELECT customer, spent FROM bycust WHERE spent > (SELECT avg(spent) FROM bycust) ORDER BY customer;
SELECT name FROM product WHERE sku IN (SELECT sku FROM line WHERE order_id = 1 INTERSECT SELECT sku FROM line WHERE order_id = 3);
SELECT sku FROM product EXCEPT SELECT sku FROM line WHERE qty > 3 ORDER BY sku;
CREATE TABLE archive (order_id INTEGER, customer TEXT);
INSERT INTO archive SELECT id, customer FROM orders WHERE day < 2;
DELETE FROM line WHERE order_id IN (SELECT order_id FROM archive);
DELETE FROM orders WHERE id IN (SELECT order_id FROM archive);
SELECT count(*) FROM line;
SELECT 'live', id, customer FROM orders UNION ALL SELECT 'old', order_id, customer FROM archive ORDER BY 2;
CREATE UNIQUE INDEX product_name ON product (name);
INSERT INTO product VALUES ('p4', 'pen', 4);
INSERT INTO product VALUES ('p4', 'cap', 2);
SELECT name, price FROM product ORDER BY price DESC, name;
SELECT name FROM product ORDER BY price LIMIT 1 OFFSET 1;
