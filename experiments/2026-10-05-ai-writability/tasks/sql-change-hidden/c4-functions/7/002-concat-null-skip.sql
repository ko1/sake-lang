-- concat: NULLs skipped, all-NULL gives empty TEXT, needs one argument
CREATE TABLE parts (pno INTEGER, prefix TEXT, code INTEGER, suffix TEXT);
INSERT INTO parts VALUES (1, 'AX', 10, NULL), (2, NULL, 20, 'b'), (3, NULL, NULL, NULL);
SELECT pno, concat(prefix, code, suffix) FROM parts ORDER BY pno;
SELECT pno, typeof(concat(prefix, code, suffix)), concat(prefix, suffix) = '' FROM parts ORDER BY pno;
SELECT pno FROM parts WHERE prefix || suffix IS NULL AND concat(prefix, suffix) IS NOT NULL ORDER BY pno;
SELECT CONCAT();
