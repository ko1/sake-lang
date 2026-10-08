CREATE TABLE tags (id INTEGER PRIMARY KEY, tag TEXT);
INSERT INTO tags (tag) VALUES ('SQL'), ('sql'), ('Sql'), ('nosql'), ('NoSQL');
SELECT id FROM tags WHERE tag GLOB '*SQL' ORDER BY id;
SELECT id FROM tags WHERE tag GLOB '*sql' ORDER BY id;
SELECT id FROM tags WHERE tag LIKE '*sql' ORDER BY id;
SELECT id FROM tags WHERE tag LIKE '%sql' ORDER BY id;
SELECT upper(tag) GLOB 'NO*', lower(tag) GLOB 'no*' FROM tags ORDER BY id;
