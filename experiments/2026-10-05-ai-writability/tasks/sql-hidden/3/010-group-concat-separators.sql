CREATE TABLE path (step INTEGER, dir TEXT);
INSERT INTO path VALUES (1, 'up'), (2, 'left'), (3, 'up'), (4, 'down');
SELECT group_concat(dir, '->' ORDER BY step) FROM path;
SELECT group_concat(dir, '-' || '>' ORDER BY step DESC) FROM path;
SELECT group_concat(step, 1.5 ORDER BY step) FROM path WHERE step < 3;
SELECT group_concat(dir, ', ' ORDER BY dir, step) FROM path;
SELECT group_concat(upper(dir), '' ORDER BY step) FROM path WHERE dir <> 'up';
