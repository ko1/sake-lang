-- the DEFAULT of an added column, converted to the column's type, for old and new rows
CREATE TABLE t (id INTEGER);
INSERT INTO t VALUES (1), (2);
ALTER TABLE t ADD COLUMN neg INTEGER DEFAULT -5;
ALTER TABLE t ADD COLUMN label TEXT DEFAULT 7;
ALTER TABLE t ADD COLUMN ratio REAL DEFAULT 2;
ALTER TABLE t ADD COLUMN note TEXT DEFAULT NULL;
ALTER TABLE t ADD COLUMN cnt INTEGER DEFAULT '12';
SELECT id, neg, label, typeof(label), ratio, note, cnt, typeof(cnt) FROM t ORDER BY id;
INSERT INTO t (id) VALUES (3);
INSERT INTO t (id, label, cnt) VALUES (4, 'x', 1);
SELECT id, neg, label, ratio, note, cnt FROM t WHERE id > 2 ORDER BY id;
SELECT sum(neg), sum(cnt) FROM t;
SELECT * FROM t WHERE label = 7 ORDER BY id;
