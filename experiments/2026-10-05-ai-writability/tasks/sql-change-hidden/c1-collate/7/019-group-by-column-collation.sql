-- GROUP BY a NOCASE column; GROUP BY an expression without collation stays BINARY.
CREATE TABLE orders (id INTEGER, cust TEXT COLLATE NOCASE, amt INTEGER);
INSERT INTO orders VALUES (1, 'acme', 5), (2, 'ACME', 7), (3, 'Zeta', 1), (4, 'zeta', 2), (5, 'Acme', 3);
SELECT upper(cust), count(*), sum(amt) FROM orders GROUP BY cust ORDER BY 1;
SELECT count(*) FROM (SELECT 1 FROM orders GROUP BY cust || '');
SELECT count(*) FROM (SELECT 1 FROM orders GROUP BY cust COLLATE BINARY);
SELECT upper(cust) AS u, sum(amt) FROM orders GROUP BY cust HAVING sum(amt) > 5 ORDER BY u;
