CREATE TABLE things (id INTEGER, label TEXT, n REAL);
INSERT INTO things VALUES (1, '10', 9.5), (2, '9', 100.0), (3, NULL, -1.0), (4, 'abc', NULL);
SELECT min(label), max(label) FROM things;
SELECT min(n), max(n) FROM things;
SELECT max(CASE id WHEN 1 THEN label ELSE n END), min(CASE id WHEN 1 THEN label ELSE n END) FROM things;
SELECT max(CAST(label AS INTEGER)), min(CAST(label AS INTEGER)) FROM things;
SELECT max(id * 1.5), typeof(max(id * 1.5)) FROM things;
