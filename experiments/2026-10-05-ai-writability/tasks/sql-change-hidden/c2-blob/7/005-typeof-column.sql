CREATE TABLE att (n INTEGER, raw BLOB, label TEXT);
INSERT INTO att VALUES (1, X'89', 'x'), (2, NULL, NULL), (3, X'', '');
SELECT n, typeof(raw), typeof(label) FROM att ORDER BY n;
SELECT typeof(raw), count(*) FROM att GROUP BY 1 ORDER BY 1;
