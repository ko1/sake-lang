CREATE TABLE codes (c TEXT);
INSERT INTO c VALUES ('x');
INSERT INTO codes VALUES ('AB-100'), ('ab-2'), ('A_B'), ('AXB'), ('100%'), ('x');
SELECT c FROM codes WHERE c LIKE 'ab-%' ORDER BY c;
SELECT c FROM codes WHERE c LIKE 'a_b' ORDER BY c;
SELECT c FROM codes WHERE c LIKE '%0%' ORDER BY c;
SELECT c FROM codes WHERE c LIKE '___' ORDER BY c;
SELECT c FROM codes WHERE c LIKE '%-_' ORDER BY c;
SELECT 'aaa' LIKE 'a%a', 'a' LIKE 'a%a', 'abc' LIKE '%', 'abc' LIKE 'a%c%';
