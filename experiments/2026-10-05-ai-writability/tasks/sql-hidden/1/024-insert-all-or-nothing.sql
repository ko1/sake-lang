CREATE TABLE q (id INTEGER, label TEXT, score REAL);
INSERT INTO q VALUES (1, 'a', 1), (2, 'b', 'two'), (3, 'c', 3);
INSERT INTO q VALUES (1, 'a', 1), (2, 'b', 2), (3.5, 'c', 3);
INSERT INTO q VALUES (1, 'a', 1), (2, 'b', nope(2));
INSERT INTO q (id, label) VALUES (1, 'a'), (2, label);
SELECT * FROM q;
INSERT INTO q VALUES (10, 'x', 1.5), (11, 'y', '2.5'), (12, 'z', NULL);
INSERT INTO q VALUES (13, 'w', 'bad');
SELECT id, label, score FROM q ORDER BY id;
