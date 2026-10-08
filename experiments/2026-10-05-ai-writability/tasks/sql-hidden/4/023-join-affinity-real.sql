-- ON compares with the columns' affinities: REAL and TEXT columns, INTEGER and plain text.
CREATE TABLE measures (m REAL, label TEXT);
CREATE TABLE notes (txt TEXT, num INTEGER);
INSERT INTO measures VALUES (2.0, 'two'), (2.5, 'two and a half'), (10.0, 'ten');
INSERT INTO notes VALUES ('2', 1), ('2.50', 2), ('1e1', 3), ('two', 4), ('10.0', 5);
SELECT label, num FROM measures JOIN notes ON m = txt ORDER BY num;
SELECT label, num FROM measures JOIN notes ON txt = m ORDER BY num;
SELECT label, num FROM measures JOIN notes ON txt = m + 0 ORDER BY num;
SELECT txt, num FROM notes JOIN measures ON num = '2' AND m = 2 ORDER BY num;
SELECT txt FROM notes JOIN measures ON txt = label ORDER BY txt;
