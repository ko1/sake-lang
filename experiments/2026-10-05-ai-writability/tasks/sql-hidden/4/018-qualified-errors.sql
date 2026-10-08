-- no such column: q.c wherever the qualified name appears.
CREATE TABLE p (id INTEGER, label TEXT);
CREATE TABLE q (id INTEGER, p_id INTEGER);
INSERT INTO p VALUES (1, 'one');
INSERT INTO q VALUES (7, 1);
SELECT p.label FROM p JOIN q ON q.pid = p.id;
SELECT count(*) FROM p JOIN q ON q.p_id = p.id GROUP BY q.label;
SELECT p.id FROM p GROUP BY p.id HAVING max(r.id) > 0;
SELECT label FROM p WHERE EXISTS (SELECT 1 FROM q WHERE q.p_id = p.ident);
SELECT s.id FROM (SELECT id AS ident FROM q) s;
SELECT Q.P_ID, P.LABEL FROM p JOIN q ON q.p_id = p.id;
SELECT label FROM p WHERE (SELECT x.id FROM q) IS NULL;
