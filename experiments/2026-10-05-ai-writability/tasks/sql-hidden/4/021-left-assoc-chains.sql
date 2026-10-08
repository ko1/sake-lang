-- (A LEFT JOIN B) JOIN C: the inner join on B's columns drops A's unmatched rows again.
CREATE TABLE a (id INTEGER, an TEXT);
CREATE TABLE b (id INTEGER, bn TEXT);
CREATE TABLE c (bn TEXT, cn TEXT);
INSERT INTO a VALUES (1, 'a1'), (2, 'a2'), (3, 'a3');
INSERT INTO b VALUES (1, 'b1'), (2, 'b2');
INSERT INTO c VALUES ('b1', 'c1'), ('zz', 'c9');
SELECT an, bn, cn FROM a LEFT JOIN b USING (id) JOIN c USING (bn) ORDER BY an;
SELECT an, bn, cn FROM a LEFT JOIN b USING (id) LEFT JOIN c USING (bn) ORDER BY an;
SELECT an, bn, cn FROM a LEFT JOIN (SELECT id, b.bn, cn FROM b JOIN c USING (bn)) j USING (id) ORDER BY an;
SELECT an, cn FROM a JOIN c ON 1 LEFT JOIN b ON b.bn = c.bn AND b.id = a.id WHERE b.id IS NULL ORDER BY an, cn;
