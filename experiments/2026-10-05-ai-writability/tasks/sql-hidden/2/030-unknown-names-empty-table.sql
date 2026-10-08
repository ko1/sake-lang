-- name errors happen before any row is read, so also on an empty table
CREATE TABLE e (x INTEGER);
UPDATE e SET y = 1;
UPDATE e SET x = y;
UPDATE e SET x = 1 WHERE y > 0;
DELETE FROM e WHERE y > 0;
DELETE FROM E WHERE X > 0;
UPDATE E SET X = 1;
UPDATE nope SET x = 1;
DELETE FROM nope WHERE x = 1;
SELECT x FROM e;
SELECT 'done';
