-- count(DISTINCT x) per group.
CREATE TABLE tags (post INTEGER, tag TEXT COLLATE NOCASE);
INSERT INTO tags VALUES (1, 'SQL'), (1, 'sql'), (1, 'Db'), (2, 'db'), (2, 'DB'), (3, 'x');
SELECT post, count(DISTINCT tag), count(tag) FROM tags GROUP BY post ORDER BY post;
SELECT post, count(DISTINCT tag COLLATE BINARY) FROM tags GROUP BY post ORDER BY post;
SELECT count(DISTINCT tag) FROM tags WHERE post < 3;
