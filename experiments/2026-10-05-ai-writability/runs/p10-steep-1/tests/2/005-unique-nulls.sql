-- a row with NULL in a UNIQUE column never conflicts
CREATE TABLE tags (label TEXT UNIQUE, n INTEGER);
INSERT INTO tags VALUES (NULL, 1), (NULL, 2);
INSERT INTO tags VALUES (NULL, 3);
INSERT INTO tags VALUES ('red', 4);
INSERT INTO tags VALUES ('red', 5);
SELECT n, label FROM tags ORDER BY n;
SELECT n FROM tags WHERE label IS NULL ORDER BY n DESC;
