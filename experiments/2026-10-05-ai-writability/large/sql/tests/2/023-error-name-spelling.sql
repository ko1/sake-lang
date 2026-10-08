-- constraint errors spell <table>.<column> as the CREATE TABLE did
CREATE TABLE Stock (ItemCode TEXT UNIQUE, OnHand INTEGER NOT NULL);
INSERT INTO stock (itemcode, onhand) VALUES ('X1', 3);
INSERT INTO STOCK (ITEMCODE, ONHAND) VALUES ('X1', 4);
insert into stock (itemcode) values ('X2');
update stock set onhand = 'lots';
SELECT itemcode, ONHAND FROM Stock;
