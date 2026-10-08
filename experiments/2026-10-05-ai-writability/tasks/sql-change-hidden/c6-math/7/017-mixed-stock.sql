-- warehouse: crates of 8, joined with products, rounded up
CREATE TABLE product (pid INTEGER PRIMARY KEY, name TEXT, unit_kg REAL);
CREATE TABLE stock (pid INTEGER, qty INTEGER);
INSERT INTO product VALUES (1, 'bolt', 0.05), (2, 'plate', 2.4), (3, 'rod', 1.75);
INSERT INTO stock VALUES (1, 100), (2, 17), (3, 8), (1, 30), (3, 3);
SELECT p.name, sum(s.qty) AS q, ceil(sum(s.qty) / 8.0) AS crates, mod(sum(s.qty), 8) AS spare
  FROM product p JOIN stock s ON s.pid = p.pid GROUP BY p.name ORDER BY p.name;
SELECT name, ceil(unit_kg * (SELECT sum(qty) FROM stock WHERE stock.pid = product.pid)) AS kg
  FROM product WHERE mod(pid, 2) = 1 ORDER BY kg;
UPDATE product SET unit_kg = trunc(unit_kg * 10) / 10 WHERE unit_kg > 1;
SELECT pid, unit_kg FROM product ORDER BY pid;
