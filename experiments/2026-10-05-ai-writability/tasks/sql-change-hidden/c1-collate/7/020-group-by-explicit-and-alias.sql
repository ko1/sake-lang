-- GROUP BY with COLLATE, by number and by alias (the result column's collation).
CREATE TABLE logs (id INTEGER, lvl TEXT, src TEXT COLLATE RTRIM);
INSERT INTO logs VALUES (1, 'warn', 'db  '), (2, 'WARN', 'db'), (3, 'Warn', 'web'), (4, 'err', 'web '), (5, 'ERR', 'db');
SELECT lower(lvl), count(*) FROM logs GROUP BY lvl COLLATE NOCASE ORDER BY 1;
SELECT rtrim(src), count(*) FROM logs GROUP BY src ORDER BY 1;
SELECT c FROM (SELECT lvl COLLATE NOCASE AS k, count(*) AS c FROM logs GROUP BY k) ORDER BY c;
SELECT count(*) FROM (SELECT src FROM logs GROUP BY 1);
SELECT count(*) FROM (SELECT lvl FROM logs GROUP BY 1);
