-- A window's ORDER BY sorts under the term's collation, and equal values are peers.
CREATE TABLE runners (id INTEGER, nm TEXT COLLATE NOCASE, raw TEXT);
INSERT INTO runners VALUES (1, 'eva', 'eva'), (2, 'Bo', 'Bo'), (3, 'EVA', 'EVA'), (4, 'al', 'al'), (5, 'Cy', 'Cy');
SELECT id, rank() OVER (ORDER BY nm), dense_rank() OVER (ORDER BY nm) FROM runners ORDER BY id;
SELECT id, row_number() OVER (ORDER BY raw, id) FROM runners ORDER BY id;
SELECT id, rank() OVER (ORDER BY raw COLLATE NOCASE DESC) FROM runners ORDER BY id;
SELECT id, count(*) OVER (ORDER BY nm) FROM runners ORDER BY id;
