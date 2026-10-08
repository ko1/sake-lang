-- A view column's implicit collation loses to a left column, and wins when it is on the left.
CREATE TABLE prod (sku TEXT COLLATE NOCASE, price INTEGER);
CREATE TABLE sale (sku TEXT, n INTEGER);
INSERT INTO prod VALUES ('Ab1', 10), ('cd2', 20);
INSERT INTO sale VALUES ('AB1', 1), ('Cd2', 2), ('cd2', 3);
CREATE VIEW pv AS SELECT sku AS s, price FROM prod;
SELECT n FROM sale, pv WHERE pv.s = sale.sku ORDER BY n;
SELECT n FROM sale, pv WHERE sale.sku = pv.s ORDER BY n;
SELECT count(*) FROM pv WHERE s IN ('ab1', 'CD2');
