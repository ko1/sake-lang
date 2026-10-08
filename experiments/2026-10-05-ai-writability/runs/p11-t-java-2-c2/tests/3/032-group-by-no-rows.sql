CREATE TABLE logs (level TEXT, msg TEXT);
SELECT level, count(*) FROM logs GROUP BY level;
INSERT INTO logs VALUES ('info', 'start'), ('warn', 'slow');
SELECT level, count(*) FROM logs WHERE level = 'error' GROUP BY level;
SELECT count(*) FROM logs WHERE level = 'error';
SELECT count(*) FROM logs GROUP BY level HAVING count(*) > 5;
SELECT 'groups', count(*) FROM logs GROUP BY level ORDER BY 2;
