-- Inner sources win over outer ones for unqualified names; qualify to reach the outer row.
CREATE TABLE box (id INTEGER, size INTEGER, label TEXT);
CREATE TABLE item (id INTEGER, size INTEGER, box_id INTEGER);
INSERT INTO box VALUES (1, 10, 'small'), (2, 50, 'big');
INSERT INTO item VALUES (1, 4, 1), (2, 7, 1), (3, 30, 2), (4, 60, 2);
SELECT label, (SELECT count(*) FROM item WHERE size < 10) FROM box ORDER BY id;
SELECT label, (SELECT count(*) FROM item WHERE item.size < box.size) FROM box ORDER BY id;
SELECT label, (SELECT count(*) FROM item i WHERE box_id = id) FROM box ORDER BY id;
SELECT label, (SELECT count(*) FROM item i WHERE box_id = box.id AND size <= box.size) FROM box ORDER BY id;
SELECT label FROM box b WHERE EXISTS (SELECT 1 FROM item WHERE box_id = b.id AND item.size > b.size) ORDER BY label;
SELECT id, (SELECT label FROM box WHERE box.id = box_id) FROM item ORDER BY id;
