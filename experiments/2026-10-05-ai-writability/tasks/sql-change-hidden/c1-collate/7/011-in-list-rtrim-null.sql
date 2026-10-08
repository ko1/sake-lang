-- IN under RTRIM, with NULLs keeping their three-valued result.
CREATE TABLE p (id INTEGER, code TEXT COLLATE RTRIM);
INSERT INTO p VALUES (1, 'A1  '), (2, 'a1'), (3, NULL), (4, 'B2 ');
SELECT id, code IN ('A1', 'B2'), code IN ('A1', NULL), code NOT IN ('B2') FROM p ORDER BY id;
SELECT id FROM p WHERE code COLLATE NOCASE IN ('a1') ORDER BY id;
SELECT id FROM p WHERE 'B2' IN (code, 'zz') ORDER BY id;
