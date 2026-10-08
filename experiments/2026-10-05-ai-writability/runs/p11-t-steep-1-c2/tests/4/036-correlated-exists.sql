CREATE TABLE customers (id INTEGER, name TEXT);
CREATE TABLE orders (cust_id INTEGER, amount INTEGER);
INSERT INTO customers VALUES (1, 'ann'), (2, 'bob'), (3, 'cid'), (4, 'dee');
INSERT INTO orders VALUES (1, 50), (1, 5), (3, 200), (4, 0);
SELECT name FROM customers c WHERE EXISTS (SELECT 1 FROM orders o WHERE o.cust_id = c.id) ORDER BY name;
SELECT name FROM customers c WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.cust_id = c.id) ORDER BY name;
SELECT name FROM customers c
  WHERE EXISTS (SELECT 1 FROM orders WHERE cust_id = c.id AND amount > 10) ORDER BY name;
SELECT name, EXISTS (SELECT 1 FROM orders WHERE cust_id = id AND amount = 0) FROM customers ORDER BY id;
SELECT name FROM customers WHERE id IN (SELECT cust_id FROM orders WHERE amount < 10) ORDER BY name;
