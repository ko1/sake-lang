CREATE TABLE tags (post INTEGER, tag TEXT);
INSERT INTO tags VALUES (1, 'sql');
SELECT group_concat(tag) FROM tags;
INSERT INTO tags VALUES (2, 'db'), (2, 'db'), (3, NULL);
SELECT group_concat(tag) FROM tags WHERE post = 2;
SELECT group_concat(tag) FROM tags WHERE post = 3;
SELECT group_concat(tag) FROM tags WHERE post = 9;
SELECT typeof(group_concat(post)) FROM tags WHERE post = 1;
