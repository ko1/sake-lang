-- With several sources on the left, USING uses the first one that has the column.
CREATE TABLE x (k INTEGER, xv TEXT);
CREATE TABLE y (yk INTEGER, k INTEGER, yv TEXT);
CREATE TABLE z (k INTEGER, zv TEXT);
INSERT INTO x VALUES (1, 'x1'), (2, 'x2'), (3, 'x3');
INSERT INTO y VALUES (1, 3, 'y1'), (2, 2, 'y2'), (3, 1, 'y3');
INSERT INTO z VALUES (1, 'z1'), (2, 'z2'), (3, 'z3');
SELECT xv, yv, zv FROM x JOIN y ON y.yk = x.k JOIN z USING (k) ORDER BY xv;
SELECT xv, yv, zv FROM y JOIN x ON y.yk = x.k JOIN z USING (k) ORDER BY xv;
SELECT x.k, y.k, z.k FROM x, y JOIN z USING (k) WHERE x.k = 1 ORDER BY y.k;
SELECT x.k, zv, yv FROM x JOIN z USING (k) LEFT JOIN y ON y.yk = x.k + 1 ORDER BY x.k;
