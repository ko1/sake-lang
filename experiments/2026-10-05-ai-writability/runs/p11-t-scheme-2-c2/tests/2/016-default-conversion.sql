-- a default value is converted to the column's type when it is stored
CREATE TABLE d (i INTEGER DEFAULT '12', r REAL DEFAULT 3, t TEXT DEFAULT 1.5, u TEXT DEFAULT +7, n INTEGER DEFAULT 2.0);
INSERT INTO d (i) VALUES (0);
INSERT INTO d (r) VALUES (0);
SELECT i, typeof(i), r, typeof(r), t, typeof(t), u, typeof(u), n, typeof(n) FROM d ORDER BY i;
CREATE TABLE bad (a INTEGER DEFAULT 'none', b INTEGER);
INSERT INTO bad (b) VALUES (1);
INSERT INTO bad (a, b) VALUES (5, 1);
SELECT a, b FROM bad;
