-- scenario: stock movements per product, running stock and reorder alerts
CREATE TABLE product (sku TEXT PRIMARY KEY, name TEXT, reorder_at INTEGER DEFAULT 5);
CREATE TABLE move (id INTEGER PRIMARY KEY, sku TEXT NOT NULL, day INTEGER, qty INTEGER NOT NULL);
INSERT INTO product VALUES ('p1', 'bolt', 20), ('p2', 'nut', 10);
INSERT INTO product (sku, name) VALUES ('p3', 'gear');
INSERT INTO product VALUES ('p1', 'dup', 1);
INSERT INTO move (sku, day, qty) VALUES ('p1',1,50),('p1',2,-15),('p1',3,-20),('p1',3,-5),('p2',1,12),('p2',4,-3),('p3',2,8),('p3',5,-4),('p3',6,-2);
SELECT m.sku, m.day, m.qty, sum(m.qty) OVER (PARTITION BY m.sku ORDER BY m.day, m.id) AS stock FROM move AS m ORDER BY m.sku, m.day, m.id;
-- stock at the end of the day, with the reorder flag
SELECT sku, day, stock, CASE WHEN stock <= reorder_at THEN 'reorder' ELSE 'ok' END FROM
  (SELECT m.sku, m.day, p.reorder_at, sum(m.qty) OVER (PARTITION BY m.sku ORDER BY m.day) AS stock FROM move AS m JOIN product AS p USING (sku))
  ORDER BY sku, day, stock;
SELECT sku, day FROM move WHERE qty < 0 ORDER BY sku, day, qty;
-- the biggest single outflow per product and its share of all outflows
SELECT sku, min(qty), min(qty) * 100 / sum(min(qty)) OVER () FROM move WHERE qty < 0 GROUP BY sku ORDER BY sku;
-- number of moves so far and the move before
SELECT id, count(*) OVER (PARTITION BY sku ORDER BY id), lag(qty, 1, 0) OVER (PARTITION BY sku ORDER BY id) FROM move ORDER BY id;
-- a transaction that ships an order, then is undone
BEGIN;
INSERT INTO move (sku, day, qty) VALUES ('p2', 5, -8), ('p3', 7, -2);
SELECT sku, sum(qty), rank() OVER (ORDER BY sum(qty)) FROM move GROUP BY sku ORDER BY sku;
ROLLBACK;
SELECT sku, sum(qty), rank() OVER (ORDER BY sum(qty)) FROM move GROUP BY sku ORDER BY sku;
-- days with movement in a 2-day window
SELECT DISTINCT sku, day, count(*) OVER (PARTITION BY sku ORDER BY day RANGE BETWEEN 1 PRECEDING AND 1 FOLLOWING) FROM move ORDER BY sku, day;
ALTER TABLE move ADD COLUMN note TEXT DEFAULT '-';
UPDATE move SET note = 'big' WHERE abs(qty) >= 15;
SELECT id, note, group_concat(note, '') OVER (PARTITION BY sku ORDER BY id ROWS BETWEEN CURRENT ROW AND 1 FOLLOWING) FROM move ORDER BY id;
SELECT p.name, (SELECT sum(qty) FROM move WHERE sku = p.sku) AS left_over FROM product AS p ORDER BY left_over, p.name;
SELECT sku, first_value(day) OVER (PARTITION BY sku ORDER BY day DESC, id DESC) AS last_day FROM move WHERE qty > 0 ORDER BY sku;
SELECT sku, max(day) OVER (PARTITION BY sku) - min(day) OVER (PARTITION BY sku) FROM move WHERE id IN (1, 4, 5, 9) ORDER BY id;
