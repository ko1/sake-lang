-- the message lists the constraint's columns in the constraint's order
CREATE TABLE cal (yr INTEGER, mo INTEGER, dy INTEGER, note TEXT, PRIMARY KEY (dy, mo, yr));
INSERT INTO cal VALUES (2026, 1, 1, 'new year'), (2026, 12, 25, 'xmas'), (2025, 1, 1, 'old year');
INSERT INTO cal VALUES (2026, 1, 1, 'again');
INSERT INTO cal VALUES (NULL, 1, 2, 'no year');
INSERT INTO cal (yr, mo, note) VALUES (2026, 2, 'no day');
UPDATE cal SET yr = 2026 WHERE note = 'old year';
UPDATE cal SET yr = 2027 WHERE note = 'old year';
SELECT yr, mo, dy, note FROM cal ORDER BY yr, mo, dy;
