-- The specification's own examples, evaluated against stored rows.
CREATE TABLE ex (k INTEGER, i INTEGER, r REAL, s TEXT);
INSERT INTO ex VALUES (1, ' 12 ', '-3.5', 1.5), (2, '12.0', '.5', 1e20), (3, '1e3', 1.0, '3.0');
INSERT INTO ex (k, i) VALUES (4, '12.5');
INSERT INTO ex (k, r) VALUES (4, '0x10');
INSERT INTO ex (k, i) VALUES (4, '12abc');
INSERT INTO ex (k, r) VALUES (4, '');
SELECT k, i, r, s FROM ex ORDER BY k;
SELECT k, s = 3, s = 3.0, i = '12', i < 'abc' FROM ex ORDER BY k;
SELECT k, NOT i = k, 2 * 3 || k, 'a' || k + 2, k < 2 = 1 FROM ex ORDER BY k;
SELECT s || '3abc' + 0, ' -2.5e1x' + k, '5.' * k, 'abc' - k, '-' + k, '1e' + k FROM ex WHERE k = 1;
SELECT -7 / 2, -7 % 2, 7 % -2, 7.5 % 2, 0.1 + 0.2, 2.0 / 3, 1e15, 1.5e-7;
SELECT r || '', length(r), abs(s), length(1.5), abs('-3') FROM ex WHERE k = 1;
SELECT 1 || 2, 1.5 || '', NULL IS NULL, NULL IS 1, 1 = 1.0, 12 = '12';
SELECT 'B' < 'a', 'abc' < 'abd', 'ab' < 'abc', -0.0, 1.0, 100.0;
SELECT k FROM ex WHERE '1x' AND k < 3 ORDER BY k;
SELECT k FROM ex WHERE 'abc' OR '0.0';
SELECT k, s FROM ex ORDER BY k, s, 3;
