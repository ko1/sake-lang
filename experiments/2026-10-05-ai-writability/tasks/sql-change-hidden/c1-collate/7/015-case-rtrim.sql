-- CASE x WHEN with an RTRIM column on either side, and searched CASE with comparisons.
CREATE TABLE s (id INTEGER, st TEXT COLLATE RTRIM, plain TEXT);
INSERT INTO s VALUES (1, 'open  ', 'open'), (2, 'shut', 'shut  '), (3, 'Open', 'open ');
SELECT id, CASE st WHEN 'open' THEN 1 WHEN 'shut' THEN 2 ELSE 0 END FROM s ORDER BY id;
SELECT id, CASE plain WHEN st THEN 'same' ELSE 'diff' END FROM s ORDER BY id;
SELECT id, CASE st WHEN plain THEN 'same' ELSE 'diff' END FROM s ORDER BY id;
SELECT id, CASE WHEN plain = 'open' COLLATE RTRIM THEN 'o' ELSE 'x' END FROM s ORDER BY id;
