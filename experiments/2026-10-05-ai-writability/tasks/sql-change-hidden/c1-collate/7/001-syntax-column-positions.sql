-- COLLATE among other column constraints, with a DEFAULT, and names in any case.
CREATE TABLE kv (k TEXT NOT NULL UNIQUE COLLATE nOcAsE, v TEXT DEFAULT 'none' COLLATE RTRIM, w TEXT COLLATE binary);
INSERT INTO kv (k) VALUES ('Port');
INSERT INTO kv VALUES ('host', 'local   ', 'Zed');
SELECT k, v FROM kv WHERE k = 'PORT';
SELECT k FROM kv WHERE v = 'local';
SELECT k FROM kv WHERE w = 'zed';
SELECT k FROM kv WHERE w = 'zed' COLLATE NOCASE;
SELECT count(*) FROM kv WHERE k IS NOT NULL AND v = 'NONE';
