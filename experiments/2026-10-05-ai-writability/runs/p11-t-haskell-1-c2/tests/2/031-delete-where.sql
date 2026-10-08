CREATE TABLE inv (item TEXT, qty INTEGER, price REAL);
INSERT INTO inv VALUES ('nut', 0, 0.1), ('bolt', 12, 0.25), ('gear', NULL, 4.5), ('cog', 3, 2.0), ('pin', 0, 0.05);
DELETE FROM inv WHERE qty = 0;
SELECT item FROM inv ORDER BY item;
DELETE FROM inv WHERE qty > 100;
DELETE FROM inv WHERE NOT qty < 5;
SELECT item, qty FROM inv ORDER BY item;
DELETE FROM inv WHERE qty IS NULL;
SELECT item, qty, price FROM inv ORDER BY item;
