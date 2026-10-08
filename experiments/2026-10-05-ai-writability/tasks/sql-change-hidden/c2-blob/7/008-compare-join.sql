CREATE TABLE a (id INTEGER, tag BLOB);
CREATE TABLE b (id INTEGER, tag BLOB, name TEXT);
INSERT INTO a VALUES (1, X'01'), (2, X'0102'), (3, NULL);
INSERT INTO b VALUES (10, X'0102', 'two'), (11, X'01', 'one'), (12, X'02', 'x');
SELECT a.id, b.name FROM a JOIN b ON a.tag = b.tag ORDER BY a.id;
SELECT a.id, b.id FROM a JOIN b ON a.tag < b.tag ORDER BY a.id, b.id;
