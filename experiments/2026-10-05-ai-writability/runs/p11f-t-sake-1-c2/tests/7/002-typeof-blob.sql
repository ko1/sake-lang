-- typeof gives 'blob'
SELECT typeof(X'41'), typeof(x''), typeof('41'), typeof(41);
SELECT typeof(NULL), typeof(X'00FF'), typeof(CAST('ab' AS BLOB));
CREATE TABLE files (name TEXT, data BLOB);
INSERT INTO files VALUES ('a', X'0102'), ('b', NULL), ('c', X'');
SELECT name, typeof(data) FROM files ORDER BY name;
