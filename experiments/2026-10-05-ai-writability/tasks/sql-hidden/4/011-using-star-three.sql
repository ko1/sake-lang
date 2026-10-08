-- * shows a USING column once even across three sources; q.* shows each source whole.
CREATE TABLE a (id INTEGER, x TEXT);
CREATE TABLE b (y TEXT, id INTEGER);
CREATE TABLE c (id INTEGER, z TEXT, y TEXT);
INSERT INTO a VALUES (1, 'ax'), (2, 'bx');
INSERT INTO b VALUES ('ay', 1), ('by', 2);
INSERT INTO c VALUES (2, 'bz', 'by'), (1, 'az', 'nope');
SELECT * FROM a JOIN b USING (id) JOIN c USING (id) ORDER BY id;
SELECT * FROM a JOIN b USING (id) JOIN c USING (id, y) ORDER BY id;
SELECT c.*, a.* FROM a JOIN c USING (id) ORDER BY a.id;
SELECT b.*, * FROM a LEFT JOIN b USING (id) WHERE id = 2;
SELECT * FROM c JOIN b USING (y, id);
