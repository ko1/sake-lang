CREATE TABLE tags (post INTEGER, tag TEXT);
CREATE TABLE posts (id INTEGER, author TEXT);
INSERT INTO posts VALUES (1, 'ann'), (2, 'bob'), (3, 'ann'), (4, 'cid');
INSERT INTO tags VALUES (1, 'sql'), (1, 'db'), (2, 'sql'), (3, 'sql'), (3, 'web'), (4, 'db');
SELECT DISTINCT author, tag FROM posts JOIN tags ON post = id ORDER BY author, tag;
SELECT DISTINCT author FROM posts JOIN tags ON post = id WHERE tag = 'sql' ORDER BY author;
SELECT author, count(DISTINCT tag) FROM posts JOIN tags ON post = id GROUP BY author ORDER BY author;
SELECT DISTINCT tag FROM tags WHERE post IN (SELECT id FROM posts WHERE author = 'ann') ORDER BY 1;
