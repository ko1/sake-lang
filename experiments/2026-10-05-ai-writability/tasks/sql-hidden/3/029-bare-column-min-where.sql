CREATE TABLE quotes (vendor TEXT, part TEXT, price INTEGER, days INTEGER);
INSERT INTO quotes VALUES ('acme', 'gear', 40, 5), ('bolt', 'gear', 35, 9), ('core', 'gear', 38, 2);
INSERT INTO quotes VALUES ('acme', 'belt', 12, 3), ('bolt', 'belt', 15, 1), ('core', 'pump', 90, 7);
SELECT part, min(price), vendor, days FROM quotes GROUP BY part ORDER BY part;
SELECT part, vendor, min(days) FROM quotes WHERE price < 39 GROUP BY part ORDER BY part;
SELECT vendor, min(price) FROM quotes WHERE part <> 'pump';
SELECT vendor || '/' || part, min(price * days) FROM quotes;
