-- a real column named rowid takes the name; _rowid_ and oid still reach the rowid
CREATE TABLE ticket (rowid TEXT, price INTEGER);
INSERT INTO ticket VALUES ('T-9', 30), ('T-4', 12);
SELECT rowid, _rowid_, oid, price FROM ticket ORDER BY price;
SELECT * FROM ticket ORDER BY oid;
INSERT INTO ticket (oid, rowid, price) VALUES (40, 'T-1', 5);
UPDATE ticket SET rowid = 'T-0' WHERE oid = 40;
SELECT oid, rowid FROM ticket WHERE rowid < 'T-5' ORDER BY oid;
SELECT typeof(rowid), typeof(_rowid_) FROM ticket WHERE price = 5;
