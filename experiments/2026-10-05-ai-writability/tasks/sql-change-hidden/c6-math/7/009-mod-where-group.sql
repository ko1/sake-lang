-- mod in WHERE and GROUP BY
CREATE TABLE seat (no INTEGER, guest TEXT);
INSERT INTO seat VALUES (1, 'ann'), (2, 'bo'), (3, 'cy'), (4, 'di'), (5, 'ed'), (6, 'flo'), (7, 'gus');
SELECT guest FROM seat WHERE mod(no, 3) = 0 ORDER BY guest;
SELECT mod(no, 3) AS r, count(*), group_concat(guest, '+' ORDER BY no) FROM seat GROUP BY r ORDER BY r;
