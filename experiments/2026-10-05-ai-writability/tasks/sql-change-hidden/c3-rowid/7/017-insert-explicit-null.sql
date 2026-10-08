-- a NULL rowid means: assign one; the list may put the rowid anywhere
CREATE TABLE pr (a TEXT, b INTEGER);
INSERT INTO pr (b, oid, a) VALUES (1, 4, 'p'), (2, NULL, 'q');
INSERT INTO pr (a, rowid) VALUES ('r', NULL);
SELECT rowid, a, b FROM pr ORDER BY rowid;
INSERT INTO pr (rowid, a, b) VALUES (9, 'x');
INSERT INTO pr VALUES (20, 'y', 3);
SELECT count(*) FROM pr;
