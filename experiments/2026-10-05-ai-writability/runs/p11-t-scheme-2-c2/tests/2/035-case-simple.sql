CREATE TABLE ship (id INTEGER, mode TEXT);
INSERT INTO ship VALUES (1, 'air'), (2, 'sea'), (3, NULL), (4, 'rail');
SELECT id, CASE mode WHEN 'air' THEN 2 WHEN 'sea' THEN 30 ELSE 7 END FROM ship ORDER BY id;
SELECT id, CASE mode WHEN NULL THEN 'null' WHEN 'rail' THEN 'train' END FROM ship ORDER BY id;
SELECT CASE 3 WHEN 1 THEN 'one' WHEN 3 THEN 'three' WHEN 3 THEN 'again' END;
SELECT CASE 2 WHEN 2.0 THEN 'equal' ELSE 'differ' END, CASE 'a' WHEN 'A' THEN 'same' ELSE 'case' END;
