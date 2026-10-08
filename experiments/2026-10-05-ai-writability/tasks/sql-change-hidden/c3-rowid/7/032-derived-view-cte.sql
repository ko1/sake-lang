-- views and ctes that list rowid carry it as an ordinary column
CREATE TABLE item (nm TEXT, qty INTEGER);
INSERT INTO item VALUES ('cup', 3), ('jar', 0), ('lid', 8);
CREATE VIEW stocked AS SELECT rowid, nm FROM item WHERE qty > 0;
SELECT rowid, nm FROM stocked ORDER BY rowid;
SELECT * FROM stocked ORDER BY nm DESC;
WITH c AS (SELECT rowid, qty FROM item) SELECT c.rowid, qty FROM c ORDER BY qty;
