CREATE TABLE Orders (OrderId INTEGER, Item TEXT NOT NULL, PRIMARY KEY (OrderId));
INSERT INTO orders (item) VALUES ('tea'), ('jam');
INSERT INTO ORDERS (orderid, item) VALUES (2, 'egg');
INSERT INTO orders (ORDERID, ITEM) VALUES (5, NULL);
INSERT INTO orders VALUES (NULL, 'oat');
SELECT orderid, item FROM orders ORDER BY OrderId;
UPDATE orders SET orderid = 1 WHERE item = 'oat';
SELECT orderid FROM Orders WHERE item = 'oat';
