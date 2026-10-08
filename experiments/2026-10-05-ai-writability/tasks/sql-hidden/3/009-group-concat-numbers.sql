CREATE TABLE ns (k INTEGER, r REAL);
INSERT INTO ns VALUES (1, 0.5), (2, 1e20), (3, 100.0), (4, NULL), (5, 1.5e-7);
SELECT group_concat(r, ' ' ORDER BY k) FROM ns;
SELECT group_concat(k, '' ORDER BY k DESC) FROM ns;
SELECT group_concat(k * 2 ORDER BY k), typeof(group_concat(k ORDER BY k)) FROM ns WHERE r IS NOT NULL;
SELECT group_concat(r) FROM ns WHERE k = 3;
SELECT length(group_concat(k ORDER BY k)) FROM ns;
