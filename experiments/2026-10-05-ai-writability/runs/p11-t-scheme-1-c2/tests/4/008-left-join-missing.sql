-- Finding left rows with no match.
CREATE TABLE products (sku TEXT, title TEXT);
CREATE TABLE sales (sku TEXT, qty INTEGER);
INSERT INTO products VALUES ('a1', 'pen'), ('b2', 'ink'), ('c3', 'pad'), ('d4', 'cap');
INSERT INTO sales VALUES ('a1', 3), ('c3', 0), ('a1', 2);
SELECT title FROM products LEFT JOIN sales ON products.sku = sales.sku WHERE sales.sku IS NULL ORDER BY title;
SELECT title FROM products LEFT JOIN sales ON products.sku = sales.sku WHERE qty IS NULL ORDER BY title;
SELECT title, coalesce(sum(qty), 0) FROM products LEFT JOIN sales ON products.sku = sales.sku
  GROUP BY title ORDER BY title;
