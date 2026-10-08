-- sign of INTEGER and REAL values
CREATE TABLE deltas (id INTEGER, d REAL, k INTEGER);
INSERT INTO deltas VALUES (1, -12.5, 3), (2, 0.0, 0), (3, 1e-9, -8), (4, NULL, NULL);
SELECT id, sign(d), sign(k) FROM deltas ORDER BY id;
SELECT id, typeof(sign(d)) FROM deltas ORDER BY id;
SELECT sign(-(-5)), sign(abs(-2)) * 100;
