-- a view may be a compound select; its names come from the first simple-select
CREATE TABLE staff (name TEXT, phone TEXT);
CREATE TABLE guests (gname TEXT, tel TEXT);
INSERT INTO staff VALUES ('ann', '111'), ('bob', '222');
INSERT INTO guests VALUES ('zed', '999'), ('ann', '111');
CREATE VIEW directory AS SELECT name, phone FROM staff UNION SELECT gname, tel FROM guests;
SELECT name, phone FROM directory ORDER BY name;
SELECT count(*) FROM directory;
INSERT INTO guests VALUES ('cat', '333');
SELECT name FROM directory WHERE phone > '200' ORDER BY phone;
CREATE VIEW only_staff AS SELECT name FROM staff EXCEPT SELECT gname FROM guests;
SELECT name FROM only_staff;
