CREATE TABLE pkt (id INTEGER, b BLOB);
INSERT INTO pkt VALUES (1, X'AA0102'), (2, X'BB0304'), (3, X'AA05');
SELECT id, substr(b, 1, 1), substr(b, 2) FROM pkt ORDER BY id;
SELECT id FROM pkt WHERE substr(b, 1, 1) = X'AA' ORDER BY id;
SELECT id, substr(b, -1), substr(b, 2, 1) FROM pkt ORDER BY id;
