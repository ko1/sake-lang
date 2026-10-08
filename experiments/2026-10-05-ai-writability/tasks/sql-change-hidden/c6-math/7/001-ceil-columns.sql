-- ceil over REAL, INTEGER and TEXT columns
CREATE TABLE fare (code TEXT, km REAL, zones INTEGER, note TEXT);
INSERT INTO fare VALUES ('a', 2.3, 2, '1.01'), ('b', 7.0, 5, ' 9 '), ('c', 0.6, 1, 'free'), ('d', NULL, 3, '-4.2');
SELECT code, ceil(km), ceiling(zones), typeof(ceiling(zones)), ceil(note), typeof(ceil(note)) FROM fare ORDER BY code;
SELECT code FROM fare WHERE ceil(km) > 2 ORDER BY code;
