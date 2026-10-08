-- a duplicate rowid is named <table>.rowid whatever name was written
CREATE TABLE reg (code TEXT);
INSERT INTO reg (rowid, code) VALUES (3, 'x'), (4, 'y');
INSERT INTO reg (oid, code) VALUES (4, 'z');
INSERT INTO reg (_rowid_, code) VALUES (5, 'z'), (3, 'w');
UPDATE reg SET oid = 3 WHERE code = 'y';
SELECT rowid, code FROM reg ORDER BY 1;
