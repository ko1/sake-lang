CREATE TABLE m (label TEXT, w REAL NOT NULL, n INTEGER NOT NULL);
INSERT INTO m VALUES ('a', 1.5, 2);
INSERT INTO m VALUES ('b', NULL, 'x');
INSERT INTO m VALUES ('c', 'heavy', NULL);
INSERT INTO m VALUES ('d', 'heavy', 3);
INSERT INTO m VALUES (NULL, '2', '3');
SELECT coalesce(label, '-'), w, n, typeof(w) FROM m ORDER BY w;
