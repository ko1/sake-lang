-- A column on the left of IN (select) beats the subquery column; an explicit COLLATE beats both.
CREATE TABLE a (id INTEGER, x TEXT, y TEXT COLLATE NOCASE);
CREATE TABLE b (z TEXT COLLATE NOCASE, q TEXT);
INSERT INTO a VALUES (1, 'Kit', 'Kit'), (2, 'kit', 'KIT'), (3, 'Max', 'max');
INSERT INTO b VALUES ('kit', 'MAX');
SELECT id FROM a WHERE x IN (SELECT z FROM b) ORDER BY id;
SELECT id FROM a WHERE x COLLATE NOCASE IN (SELECT z FROM b) ORDER BY id;
SELECT id FROM a WHERE y IN (SELECT q FROM b) ORDER BY id;
SELECT id FROM a WHERE y IN (SELECT q COLLATE BINARY FROM b) ORDER BY id;
SELECT id FROM a WHERE 'KIT' IN (SELECT z FROM b) ORDER BY id;
