-- USING after several sources compares with the first source joined so far that has the column.
CREATE TABLE p (id INTEGER, pname TEXT);
CREATE TABLE q (qid INTEGER, id INTEGER);
CREATE TABLE r (id INTEGER, rname TEXT);
INSERT INTO p VALUES (1, 'p1'), (2, 'p2');
INSERT INTO q VALUES (1, 2), (2, 1);
INSERT INTO r VALUES (1, 'r1'), (2, 'r2');
SELECT pname, qid, rname FROM p JOIN q ON p.id = q.qid JOIN r USING (id) ORDER BY pname;
SELECT p.id, q.id, r.id FROM p JOIN q ON p.id = q.qid JOIN r USING (id) ORDER BY p.id;
CREATE TABLE s (id INTEGER, tag TEXT);
INSERT INTO s VALUES (1, 'x'), (2, 'y');
SELECT id, rname, tag FROM r JOIN s USING (id) JOIN p USING (id) ORDER BY id;
SELECT * FROM r JOIN s USING (id) JOIN p USING (id) ORDER BY id;
