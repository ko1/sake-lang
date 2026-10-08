-- PRIMARY KEY (c) alone on an INTEGER column is also the row's key
CREATE TABLE logs (n INTEGER, msg TEXT, PRIMARY KEY (n));
INSERT INTO logs (msg) VALUES ('boot'), ('ready');
INSERT INTO logs VALUES (7, 'warn');
INSERT INTO logs VALUES (2, 'dup');
INSERT INTO logs (msg) VALUES ('stop');
SELECT n, msg FROM logs ORDER BY n;
