SELECT 0 / 0, 0.0 / 0.0, -5 / 0;
SELECT 3 % 0.4, 3 % -0.9;
SELECT 10 / '0', 10 / 'zero', 10 % '';
SELECT 10 / (5 - 5), coalesce(10 / 0, 'n/a');
SELECT (1 / 0) IS NULL, typeof(1.5 / 0);
CREATE TABLE z (num INTEGER, den REAL);
INSERT INTO z VALUES (1, 0), (2, 0.5), (3, NULL);
SELECT num, num / den, num % den FROM z ORDER BY num;
SELECT num FROM z WHERE num / den IS NULL ORDER BY num;
