CREATE TABLE mw (id INTEGER, val INTEGER, t TEXT);
INSERT INTO mw VALUES (1, 10, 'a'), (2, 20, 'b');
SELECT id FROM mw WHERE CASE WHEN total(val) > 5 THEN 1 ELSE 0 END;
SELECT id FROM mw WHERE abs(min(val)) > 1;
SELECT id FROM mw WHERE group_concat(t) LIKE '%a%';
SELECT id FROM mw WHERE COUNT(DISTINCT t) = 2;
SELECT id FROM mw WHERE val IN (1, AVG(val));
SELECT id FROM mw WHERE min(val, 15) = 15;
