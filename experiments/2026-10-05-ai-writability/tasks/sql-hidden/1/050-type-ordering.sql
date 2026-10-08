SELECT NULL < -1000, -1000 < 'a', 1e100 < '', 'a' > 5;
SELECT 2 < '10', '2' < '10', 2 < 10;
CREATE TABLE o (id INTEGER, i INTEGER, t TEXT);
INSERT INTO o VALUES (1, 30, NULL), (2, NULL, '30'), (3, NULL, 'Z'), (4, -5, NULL), (5, NULL, NULL), (6, NULL, '100');
SELECT id, coalesce(i, t) AS v FROM o ORDER BY v, id;
SELECT id FROM o ORDER BY coalesce(t, i) DESC, id;
SELECT id FROM o ORDER BY coalesce(i, t) DESC NULLS FIRST;
SELECT id FROM o WHERE coalesce(i, t) < 'A' ORDER BY id;
SELECT id FROM o WHERE coalesce(i, t) >= 0 ORDER BY id;
