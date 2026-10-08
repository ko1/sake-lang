-- COLLATE binds tighter than binary operators and keeps the value and the affinity.
CREATE TABLE m (n INTEGER, r REAL, s TEXT);
INSERT INTO m VALUES (7, 2.5, 'Seven');
SELECT n COLLATE NOCASE * 2, r COLLATE RTRIM + 1, s COLLATE NOCASE || '!' FROM m;
SELECT typeof(n COLLATE NOCASE), typeof(s COLLATE RTRIM), length(s COLLATE NOCASE) FROM m;
SELECT n COLLATE NOCASE = '7', r COLLATE NOCASE = ' 2.5 ', s COLLATE NOCASE = 'SEVEN' FROM m;
SELECT 'Q' COLLATE NOCASE = 'q' AND 'q' = 'Q', 'Q' = 'q' COLLATE NOCASE OR 0;
SELECT 1 FROM m WHERE NOT s = 'seven' COLLATE NOCASE;
SELECT 2 FROM m WHERE NOT s = 'seven';
