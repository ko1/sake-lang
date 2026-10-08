CREATE TABLE p (g TEXT, h BLOB);
INSERT INTO p VALUES ('x', X'02'), ('y', X'01'), ('x', X'01'), ('y', X'0201');
SELECT g, h FROM p ORDER BY g DESC, h;
SELECT g, h FROM p ORDER BY h DESC, g;
