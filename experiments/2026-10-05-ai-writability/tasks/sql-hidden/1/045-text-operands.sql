SELECT '6' / '4', '6.0' / '4', '6' / '4.0';
SELECT '2' * '2.5', '2' - '5';
SELECT 'ten' + 10, '10ten' + 10;
SELECT typeof('6' / '4'), typeof('6.0' / '4');
SELECT '9' % '4', '9.9' % '4';
CREATE TABLE q (s TEXT, i INTEGER);
INSERT INTO q VALUES ('3', 4), ('1.5', 2), ('two', 2), ('8 items', 2);
SELECT s, s * i, i - s, s / i FROM q ORDER BY s;
SELECT s FROM q WHERE s + 0 > 2 ORDER BY s;
