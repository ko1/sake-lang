-- NULL arguments are skipped; all NULL gives '' (not NULL)
SELECT concat('a', NULL, 'b');
SELECT 'a' || NULL || 'b';
SELECT concat(NULL, 'only');
SELECT concat(NULL), typeof(concat(NULL));
SELECT concat(NULL, NULL, NULL) IS NULL, length(concat(NULL, NULL));
SELECT concat(NULL, 4, NULL, 5);
