-- A restaurant: tables, menu, orders.
CREATE TABLE menu (dish TEXT PRIMARY KEY, course TEXT NOT NULL, price REAL);
CREATE TABLE tabs (tab INTEGER PRIMARY KEY, seat_count INTEGER, waiter TEXT);
CREATE TABLE ordered (tab INTEGER, dish TEXT, n INTEGER DEFAULT 1);
INSERT INTO menu VALUES ('soup', 'starter', 6.5), ('salad', 'starter', 7.0), ('steak', 'main', 24.0),
  ('fish', 'main', 19.5), ('cake', 'dessert', 5.25), ('pie', 'dessert', 4.75), ('bread', 'starter', 3.0);
INSERT INTO tabs VALUES (1, 2, 'Ida'), (2, 4, 'Ola'), (3, 6, 'Ida'), (4, 2, 'Pia');
INSERT INTO ordered VALUES (1, 'soup', 2), (1, 'steak', 1), (1, 'fish', 1), (2, 'salad', 4), (2, 'fish', 4),
  (3, 'steak', 6), (3, 'cake', 3), (3, 'pie', 3);
INSERT INTO ordered (tab, dish) VALUES (2, 'pie');
INSERT INTO menu VALUES ('tea', NULL, 2.0);
-- bill per table
SELECT tab, sum(n * price) AS bill FROM ordered JOIN menu USING (dish) GROUP BY tab ORDER BY tab;
-- waiters' takings, waiters with idle tables too
SELECT waiter, total(n * price) FROM tabs LEFT JOIN ordered USING (tab) LEFT JOIN menu USING (dish)
  GROUP BY waiter ORDER BY waiter;
-- dishes nobody ordered
SELECT dish FROM menu WHERE dish NOT IN (SELECT dish FROM ordered) ORDER BY dish;
-- tables that had a full meal: starter, main and dessert
SELECT tab FROM tabs t WHERE (SELECT count(DISTINCT course) FROM ordered o JOIN menu m ON m.dish = o.dish
  WHERE o.tab = t.tab) = 3 ORDER BY tab;
-- most popular dish per course by portions
SELECT course, dish, portions FROM (SELECT course, dish, sum(n) AS portions FROM menu JOIN ordered USING (dish)
  GROUP BY dish) x WHERE portions = (SELECT max(p) FROM (SELECT m2.course AS c, sum(n) AS p FROM menu m2
  JOIN ordered o2 ON o2.dish = m2.dish GROUP BY m2.dish) WHERE c = x.course) ORDER BY course;
-- average bill per seat, tables with orders only
SELECT tab, round(b.bill / seat_count, 2) FROM tabs JOIN (SELECT tab, sum(n * price) AS bill FROM ordered
  JOIN menu USING (dish) GROUP BY tab) b USING (tab) ORDER BY tab;
UPDATE menu SET price = price + 1.0 WHERE dish IN (SELECT dish FROM ordered GROUP BY dish HAVING sum(n) >= 7);
SELECT dish, price FROM menu ORDER BY dish;
SELECT dish, price FROM ordered JOIN menu ON menu.dish = ordered.dish WHERE tab = 1;
SELECT tab FROM tabs WHERE seat_count IN (SELECT tab, n FROM ordered WHERE dish = 'soup');
SELECT waiter FROM tabs WHERE EXISTS (SELECT 1 FROM ordered WHERE ordered.tab = tabs.tab AND dish = 'pie') ORDER BY tab;
SELECT course, count(DISTINCT tab) FROM menu JOIN ordered USING (dish) GROUP BY course ORDER BY course;
