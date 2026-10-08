-- min and max as window functions use the argument's collation.
CREATE TABLE q (id INTEGER, v TEXT COLLATE NOCASE);
INSERT INTO q VALUES (1, 'm'), (2, 'B'), (3, 'z'), (4, 'A'), (5, 'Q');
SELECT id, max(v) OVER (ORDER BY id), min(v) OVER (ORDER BY id) FROM q ORDER BY id;
SELECT id, max(v COLLATE BINARY) OVER (ORDER BY id ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) FROM q ORDER BY id;
