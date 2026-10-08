CREATE TABLE files (name TEXT);
INSERT INTO files VALUES ('notes.txt'), ('photo.jpg'), ('todo.txt'), ('txt'), ('archive.txt.gz'), ('readme');
SELECT name FROM files WHERE name GLOB '*.txt' ORDER BY name;
SELECT name FROM files WHERE name GLOB '*txt*' ORDER BY name;
SELECT name FROM files WHERE name GLOB 'r*' ORDER BY name;
SELECT name FROM files WHERE name GLOB 'readme' ORDER BY name;
SELECT name FROM files WHERE name GLOB 'read' ORDER BY name;
-- the pattern must match the whole text
SELECT 'abc' GLOB 'abc', 'abc' GLOB 'ab', 'abc' GLOB 'bc', 'abc' GLOB 'a*', 'abc' GLOB '*c';
SELECT '' GLOB '*', '' GLOB '', 'x' GLOB '', 'abc' GLOB '***', 'ab' GLOB 'a*b*';
SELECT 'a.b.c' GLOB '*.*', 'abc' GLOB '*.*', 'aXbXc' GLOB 'a*c';
