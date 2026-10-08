CREATE TABLE stock (code TEXT PRIMARY KEY, descr TEXT, qty INTEGER);
CREATE TABLE rules (pattern TEXT, zone TEXT);
INSERT INTO stock VALUES ('AX-100', 'bolt 5mm', 40), ('AX-210', 'nut_5mm', 15), ('BX-100', 'bolt 8mm', 0),
  ('cx-300', 'washer', 7), ('C9-001', '50% recycled', 12);
INSERT INTO rules VALUES ('A?-*', 'north'), ('[BC]*', 'south'), ('[^A-Z]*', 'misc');
SELECT s.code, r.zone FROM stock s JOIN rules r ON s.code GLOB r.pattern ORDER BY s.code, r.zone;
SELECT r.zone, count(s.code) FROM rules r LEFT JOIN stock s ON s.code GLOB r.pattern
  GROUP BY r.zone ORDER BY r.zone;
UPDATE stock SET qty = qty + 100 WHERE descr LIKE '%^_%' ESCAPE '^';
SELECT code, qty FROM stock WHERE code GLOB '*[0-9][0-9][0-9]' AND qty > 10 ORDER BY qty DESC;
DELETE FROM stock WHERE code NOT GLOB '[A-Z]*';
SELECT group_concat(code, ' ' ORDER BY code) FROM stock;
