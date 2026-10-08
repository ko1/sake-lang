SELECT 7 = '7', '7' = 7, 7 IS '7', 7 IS NOT '7';
SELECT 7 < '6', '7' > 70, 0 = '';
SELECT 1.5 = '1.5', '1.5' = 1.5 + 0;
CREATE TABLE c (i INTEGER, s TEXT);
INSERT INTO c VALUES (7, '7');
SELECT i = s, s = i, i < s, i IS s FROM c;
SELECT i * 1 = s, s || '' = i, -i = '-7', i = '7' FROM c;
SELECT length(s) = '1', coalesce(i, 0) = 7, upper(s) = 7 FROM c;
SELECT coalesce(i, 0) = '7', ifnull(s, '') = 7, nullif(s, 7) FROM c;
