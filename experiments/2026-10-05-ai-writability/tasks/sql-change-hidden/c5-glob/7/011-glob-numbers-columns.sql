CREATE TABLE phones (id INTEGER PRIMARY KEY, num INTEGER, price REAL, ext TEXT);
INSERT INTO phones (num, price, ext) VALUES (5551234, 10, '01'), (4441234, 2.5, '1'), (5559000, 100.25, '001');
SELECT id FROM phones WHERE num GLOB '555*' ORDER BY id;
SELECT id FROM phones WHERE num GLOB '*[0-4]' ORDER BY id;
SELECT id, price GLOB '*.0', price GLOB '*.?5' FROM phones ORDER BY id;
-- no affinity conversion: the column's text is matched as stored
SELECT id FROM phones WHERE ext GLOB 1 ORDER BY id;
SELECT id FROM phones WHERE ext GLOB '*1' ORDER BY id;
