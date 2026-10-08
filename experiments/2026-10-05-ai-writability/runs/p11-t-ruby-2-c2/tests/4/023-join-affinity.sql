-- Comparisons in ON use the columns' affinities.
CREATE TABLE codes (code TEXT, meaning TEXT);
CREATE TABLE events (num INTEGER, at REAL);
INSERT INTO codes VALUES ('7', 'seven'), ('07', 'oh-seven'), ('8.0', 'eight'), ('x', 'ex');
INSERT INTO events VALUES (7, 1.5), (8, 2.5), (9, 3.5);
SELECT num, meaning FROM events JOIN codes ON code = num ORDER BY num, meaning;
SELECT num, meaning FROM events JOIN codes ON num = code ORDER BY num, meaning;
SELECT at, meaning FROM events JOIN codes ON code = at * 2 + 1 ORDER BY at;
SELECT num, meaning FROM events JOIN codes ON code = num || '' ORDER BY num;
