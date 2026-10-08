CREATE TABLE paths (id INTEGER PRIMARY KEY, p TEXT);
INSERT INTO paths (p) VALUES ('my_file.txt'), ('myfile.txt'), ('my_dir/'), ('100%'), ('100'), ('my/file');
SELECT id FROM paths WHERE p LIKE 'my/_%' ESCAPE '/' ORDER BY id;
SELECT id FROM paths WHERE p LIKE '%//%' ESCAPE '/' ORDER BY id;
SELECT id FROM paths WHERE p LIKE '%=%' ESCAPE '=' ORDER BY id;
SELECT id FROM paths WHERE p NOT LIKE '%=_%' ESCAPE '=' ORDER BY id;
SELECT id, p LIKE '%.TXT' ESCAPE '!' FROM paths ORDER BY id;
