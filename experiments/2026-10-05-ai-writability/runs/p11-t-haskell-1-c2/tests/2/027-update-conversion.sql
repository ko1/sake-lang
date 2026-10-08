-- UPDATE stores values with the column-type rules
CREATE TABLE v (i INTEGER, r REAL, t TEXT);
INSERT INTO v VALUES (1, 1.0, 'one');
UPDATE v SET i = '42', r = '2.5', t = 3.0;
SELECT i, typeof(i), r, typeof(r), t, typeof(t) FROM v;
UPDATE v SET i = 7.0, r = 7, t = 7;
SELECT i, typeof(i), r, typeof(r), t, typeof(t) FROM v;
UPDATE v SET i = 7.5;
UPDATE v SET r = 'seven';
UPDATE v SET i = ' 8 ', t = 1e20;
SELECT i, r, t FROM v;
