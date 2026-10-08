-- session tokens with a transaction and an index
CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT NOT NULL);
CREATE TABLE tokens (tok BLOB PRIMARY KEY, uid INTEGER NOT NULL, ttl INTEGER DEFAULT 60);
INSERT INTO users (name) VALUES ('ann'), ('bob'), ('cy');
INSERT INTO tokens (tok, uid) VALUES (X'A001', 1), (X'B002', 2), (X'A002', 1);
BEGIN;
INSERT INTO tokens (tok, uid) VALUES (X'C003', 3);
INSERT INTO tokens (tok, uid) VALUES (x'a001', 3);
DELETE FROM tokens WHERE uid = 2;
ROLLBACK;
SELECT u.name, count(t.tok), max(t.tok) FROM users u LEFT JOIN tokens t ON t.uid = u.id GROUP BY u.name ORDER BY u.name;
SELECT hex(tok), uid FROM tokens WHERE tok BETWEEN X'A0' AND X'A0FF' ORDER BY tok;
SELECT name FROM users WHERE id NOT IN (SELECT uid FROM tokens) ORDER BY name;
UPDATE tokens SET ttl = ttl * 2 WHERE substr(tok, 1, 1) = X'B0';
SELECT hex(tok), ttl, coalesce(nullif(tok, X'B002'), 'gone') FROM tokens ORDER BY tok;
ALTER TABLE users ADD COLUMN avatar BLOB DEFAULT X'';
SELECT name, length(avatar), typeof(avatar) FROM users ORDER BY name;
