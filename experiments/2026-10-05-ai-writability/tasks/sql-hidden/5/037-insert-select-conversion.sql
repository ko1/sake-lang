-- values from a select are stored with the column's type, as VALUES rows are
CREATE TABLE raw (s TEXT);
CREATE TABLE typed (i INTEGER, r REAL, t TEXT);
INSERT INTO raw VALUES ('12'), (' 7 '), ('2.0'), ('1e2');
INSERT INTO typed SELECT s, s, s FROM raw;
SELECT i, typeof(i), r, typeof(r), t, typeof(t) FROM typed ORDER BY i;
INSERT INTO typed SELECT 3, 3, 3 UNION ALL SELECT 4.0, 4.0, 4.0;
SELECT i, r, t FROM typed WHERE i < 5 ORDER BY i;
INSERT INTO typed (i) SELECT '2.5';
INSERT INTO typed (r) SELECT 'abc';
INSERT INTO typed (i) SELECT s FROM raw WHERE s = '12' UNION ALL SELECT 'x9';
SELECT count(*) FROM typed;
