-- Joins associate to the left: a later ON may use every source joined before it.
CREATE TABLE cust (id INTEGER, name TEXT);
CREATE TABLE ord (id INTEGER, cust_id INTEGER);
CREATE TABLE ship (ord_id INTEGER, carrier TEXT);
INSERT INTO cust VALUES (1, 'ann'), (2, 'bob'), (3, 'cid');
INSERT INTO ord VALUES (10, 1), (11, 1), (12, 2);
INSERT INTO ship VALUES (10, 'ups'), (12, 'dhl');
SELECT name, ord.id, carrier FROM cust JOIN ord ON ord.cust_id = cust.id
  LEFT JOIN ship ON ship.ord_id = ord.id ORDER BY ord.id;
SELECT name, ord.id, carrier FROM cust LEFT JOIN ord ON ord.cust_id = cust.id
  LEFT JOIN ship ON ship.ord_id = ord.id ORDER BY name, ord.id;
SELECT name, ord.id FROM cust LEFT JOIN ord ON ord.cust_id = cust.id
  JOIN ship ON ship.ord_id = ord.id ORDER BY name;
SELECT name, carrier FROM cust, ord LEFT JOIN ship ON ship.ord_id = ord.id AND cust.id = 1
  WHERE ord.cust_id = cust.id ORDER BY name, ord.id;
