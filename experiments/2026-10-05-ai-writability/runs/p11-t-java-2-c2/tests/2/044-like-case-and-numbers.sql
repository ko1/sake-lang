-- LIKE ignores ASCII case and works on text forms of numbers
SELECT 'Hello' LIKE 'hello', 'HELLO' LIKE 'h%O', 'abc' LIKE 'A_C';
SELECT 123 LIKE '1%', 123 LIKE 12, 1.5 LIKE '1._', 2.0 LIKE '2', 2.0 LIKE '2.0';
CREATE TABLE ph (num INTEGER, tag TEXT);
INSERT INTO ph VALUES (5551234, 'Home'), (5559876, 'WORK'), (4441234, 'home');
SELECT num FROM ph WHERE num LIKE '555%' ORDER BY num;
SELECT num FROM ph WHERE tag LIKE 'HOME' ORDER BY num;
SELECT num FROM ph WHERE num LIKE '%1234' AND tag LIKE 'h%' ORDER BY num DESC;
