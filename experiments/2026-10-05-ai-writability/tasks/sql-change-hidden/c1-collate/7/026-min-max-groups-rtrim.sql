-- min and max per group, and under RTRIM.
CREATE TABLE g (k INTEGER, s TEXT COLLATE NOCASE, r TEXT COLLATE RTRIM);
INSERT INTO g VALUES (1, 'b', 'ab '), (1, 'C', 'ab!'), (2, 'a', 'z'), (2, 'Z', 'y  '), (2, NULL, NULL);
SELECT k, min(s), max(s) FROM g GROUP BY k ORDER BY k;
SELECT k, min(r), max(r) FROM g GROUP BY k ORDER BY k;
SELECT k, max(s COLLATE BINARY) FROM g GROUP BY k ORDER BY k;
