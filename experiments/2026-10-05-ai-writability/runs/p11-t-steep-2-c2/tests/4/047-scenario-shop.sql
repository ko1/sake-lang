-- A shop with customers, orders and order lines.
CREATE TABLE customers (id INTEGER PRIMARY KEY, name TEXT, city TEXT);
CREATE TABLE products (sku TEXT PRIMARY KEY, price REAL);
CREATE TABLE orders (id INTEGER PRIMARY KEY, cust INTEGER, day INTEGER);
CREATE TABLE lines (order_id INTEGER, sku TEXT, qty INTEGER, PRIMARY KEY (order_id, sku));
INSERT INTO customers VALUES (1, 'Ann', 'Oslo'), (2, 'Bob', 'Rome'), (3, 'Cid', 'Oslo'), (4, 'Dee', 'Lima');
INSERT INTO products VALUES ('pen', 1.5), ('ink', 4.25), ('pad', 3.0);
INSERT INTO orders VALUES (100, 1, 1), (101, 2, 1), (102, 1, 2), (103, 3, 3);
INSERT INTO lines VALUES (100, 'pen', 2), (100, 'pad', 1), (101, 'ink', 3), (102, 'pen', 10), (103, 'pad', 2);
INSERT INTO lines VALUES (102, 'pen', 1);
-- the value of each order
SELECT o.id, sum(l.qty * p.price) AS value FROM orders o JOIN lines l ON l.order_id = o.id
  JOIN products p USING (sku) GROUP BY o.id ORDER BY o.id;
-- revenue per city, cities without orders shown as 0.0
SELECT city, total(qty * price) FROM customers c LEFT JOIN orders o ON o.cust = c.id
  LEFT JOIN lines ON order_id = o.id LEFT JOIN products USING (sku) GROUP BY city ORDER BY city;
-- customers who never ordered
SELECT name FROM customers WHERE id NOT IN (SELECT cust FROM orders) ORDER BY name;
-- the best customer by value
SELECT name FROM customers WHERE id = (SELECT o.cust FROM orders o JOIN lines l ON l.order_id = o.id
  JOIN products p ON p.sku = l.sku GROUP BY o.cust ORDER BY sum(qty * price) DESC LIMIT 1);
-- products ordered by somebody in Oslo
SELECT sku FROM products WHERE sku IN (SELECT sku FROM lines JOIN orders ON orders.id = order_id
  JOIN customers ON customers.id = cust WHERE city = 'Oslo') ORDER BY sku;
-- price rise for products sold more than 5 units
UPDATE products SET price = price * 2 WHERE sku IN (SELECT sku FROM lines GROUP BY sku HAVING sum(qty) > 5);
SELECT * FROM products ORDER BY sku;
-- orders with each order's line count, newest first
SELECT id, day, (SELECT count(*) FROM lines WHERE order_id = orders.id) AS n FROM orders ORDER BY day DESC, id;
SELECT sku FROM lines JOIN products USING (sku) WHERE price > 3 ORDER BY order_id;
SELECT name FROM customers, orders WHERE id = cust;
SELECT * FROM orders JOIN customers USING (city);
DELETE FROM orders WHERE NOT EXISTS (SELECT 1 FROM lines WHERE order_id = 103) AND id = 103;
SELECT count(*) FROM orders;
