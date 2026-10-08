-- A view column carries the collation of its defining expression as an implicit one.
CREATE TABLE staff (id INTEGER, name TEXT COLLATE NOCASE, code TEXT);
INSERT INTO staff VALUES (1, 'Ola', 'ola'), (2, 'pia', 'PIA'), (3, 'Ray', 'ray');
CREATE VIEW sv AS SELECT id, name, code, code COLLATE NOCASE AS ci, upper(name) AS up FROM staff;
SELECT id FROM sv WHERE name = 'OLA';
SELECT id FROM sv WHERE ci = 'ray';
SELECT id FROM sv WHERE ci = up ORDER BY id;
SELECT id FROM sv WHERE up = ci ORDER BY id;
SELECT id FROM sv WHERE up = 'Pia';
SELECT id FROM sv WHERE name = up ORDER BY id;
SELECT id FROM sv ORDER BY ci DESC;
