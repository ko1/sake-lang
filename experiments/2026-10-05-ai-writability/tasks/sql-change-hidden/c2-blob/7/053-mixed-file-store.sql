-- a tiny file store: content blobs, hashes, dedupe
CREATE TABLE files (id INTEGER PRIMARY KEY, path TEXT NOT NULL UNIQUE, body BLOB NOT NULL, kind BLOB DEFAULT X'00');
INSERT INTO files (path, body) VALUES ('/a.txt', CAST('hello' AS BLOB)), ('/b.txt', CAST('world' AS BLOB));
INSERT INTO files (path, body, kind) VALUES ('/c.bin', X'0001FF', X'01'), ('/d.txt', CAST('hello' AS BLOB), X'00');
INSERT INTO files (path, body) VALUES ('/e.txt', 'not a blob');
INSERT INTO files (path, body) VALUES ('/a.txt', X'00');
SELECT id, path, length(body), hex(kind) FROM files ORDER BY id;
SELECT hex(body), count(*), group_concat(path, ' ' ORDER BY path) FROM files GROUP BY body HAVING count(*) > 1;
SELECT kind, count(*), sum(length(body)) FROM files GROUP BY kind ORDER BY kind;
UPDATE files SET body = body || X'21' WHERE id = 2;
UPDATE files SET body = CAST(CAST(body AS TEXT) || '!' AS BLOB) WHERE id = 2;
SELECT path, CAST(body AS TEXT) FROM files WHERE kind = X'00' ORDER BY path;
SELECT path FROM files WHERE instr(body, X'FF') > 0;
SELECT f.path, g.path FROM files f JOIN files g ON f.body = g.body AND f.id < g.id ORDER BY 1;
