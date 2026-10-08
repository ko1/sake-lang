-- A tag cloud: counting tags case-insensitively with ctes, DISTINCT and compound selects.
CREATE TABLE posts (id INTEGER, author TEXT);
CREATE TABLE post_tags (post INTEGER, tag TEXT COLLATE NOCASE);
INSERT INTO posts VALUES (1, 'kim'), (2, 'lee'), (3, 'kim');
INSERT INTO post_tags VALUES (1, 'SQL'), (1, 'Rust'), (2, 'sql'), (2, 'Go'), (3, 'RUST'), (3, 'sql');
WITH counts AS (SELECT upper(tag) AS t, count(*) AS n FROM post_tags GROUP BY tag)
SELECT t, n FROM counts ORDER BY n DESC, t;
SELECT author, count(DISTINCT tag) FROM posts JOIN post_tags ON post = id GROUP BY author ORDER BY author;
SELECT count(*) FROM (SELECT tag FROM post_tags UNION SELECT 'go' UNION SELECT 'Zig');
SELECT id FROM posts WHERE EXISTS (SELECT 1 FROM post_tags WHERE post = id AND tag = 'rust') ORDER BY id;
SELECT upper(tag), CASE tag WHEN 'sql' THEN 'db' ELSE 'lang' END FROM post_tags WHERE post = 3 ORDER BY tag;
