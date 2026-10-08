CREATE TABLE item (id INTEGER, label TEXT, price INTEGER);
CREATE TABLE stock (item_id INTEGER, qty INTEGER);
INSERT INTO item VALUES (1, 'bolt', 3), (2, 'nut', 1), (3, 'gear', 12);
INSERT INTO stock VALUES (1, 100), (3, 4), (2, 0);
SELECT i.label, s.qty FROM item AS i JOIN stock AS s ON s.item_id = i.id ORDER BY i.label;
SELECT i.label, s.qty * i.price AS worth FROM item i JOIN stock s ON s.item_id = i.id ORDER BY worth DESC;
SELECT I.LABEL FROM item i JOIN stock s ON S.ITEM_ID = I.ID WHERE s.qty = 0;
SELECT i.* FROM item i WHERE i.price > 2 ORDER BY i.id;
SELECT label FROM item x WHERE x.id = 2;
