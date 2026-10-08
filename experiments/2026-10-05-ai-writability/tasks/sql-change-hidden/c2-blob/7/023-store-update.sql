CREATE TABLE doc (id INTEGER, body BLOB, n INTEGER, x REAL);
INSERT INTO doc VALUES (1, X'01', 1, 1.0), (2, X'02', 2, 2.0);
UPDATE doc SET body = 'text';
UPDATE doc SET body = id;
UPDATE doc SET n = body WHERE id = 2;
UPDATE doc SET x = X'312E30';
UPDATE doc SET body = X'0A0B' WHERE id = 1;
SELECT id, body, n, x FROM doc ORDER BY id;
