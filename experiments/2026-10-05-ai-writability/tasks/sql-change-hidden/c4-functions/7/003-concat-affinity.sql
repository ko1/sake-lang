-- concat results have no affinity; a column's affinity still applies
CREATE TABLE nums (n INTEGER, s TEXT);
INSERT INTO nums VALUES (25, '25'), (7, '7.0');
SELECT concat(2, 5) = 25, concat(2, 5) = '25';
SELECT n FROM nums WHERE n = concat(2, 5) ORDER BY n;
SELECT n FROM nums WHERE s = concat(7, '.', 0) ORDER BY n;
SELECT concat(n, '') < 3 FROM nums ORDER BY n;
