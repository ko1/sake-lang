-- CASE x WHEN v compares as x = v.
CREATE TABLE ev (id INTEGER, kind TEXT COLLATE NOCASE, raw TEXT);
INSERT INTO ev VALUES (1, 'Error', 'Error'), (2, 'WARN', 'WARN'), (3, 'info', 'info');
SELECT id, CASE kind WHEN 'error' THEN 'E' WHEN 'warn' THEN 'W' ELSE '?' END FROM ev ORDER BY id;
SELECT id, CASE raw WHEN 'error' THEN 'E' WHEN 'warn' THEN 'W' ELSE '?' END FROM ev ORDER BY id;
SELECT id, CASE raw WHEN 'ERROR' COLLATE NOCASE THEN 'E' ELSE '-' END FROM ev ORDER BY id;
SELECT id, CASE 'INFO' WHEN kind THEN 'yes' ELSE 'no' END FROM ev ORDER BY id;
