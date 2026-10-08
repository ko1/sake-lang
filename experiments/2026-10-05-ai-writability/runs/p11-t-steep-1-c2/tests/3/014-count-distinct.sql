CREATE TABLE orders (customer TEXT, item TEXT);
INSERT INTO orders VALUES ('ann', 'pen'), ('ann', 'ink'), ('bob', 'pen'), ('bob', NULL), ('Ann', 'pen');
SELECT count(DISTINCT customer), count(customer) FROM orders;
SELECT count(DISTINCT item), count(item), count(*) FROM orders;
SELECT count(DISTINCT lower(customer)) FROM orders;
SELECT item, count(DISTINCT customer) FROM orders WHERE item IS NOT NULL GROUP BY item ORDER BY item;
