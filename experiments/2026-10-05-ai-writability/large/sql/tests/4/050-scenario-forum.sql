-- A forum: users, threads, posts and likes.
CREATE TABLE users (uid INTEGER PRIMARY KEY, handle TEXT UNIQUE NOT NULL);
CREATE TABLE threads (tid INTEGER PRIMARY KEY, title TEXT, starter INTEGER);
CREATE TABLE posts (id INTEGER PRIMARY KEY, tid INTEGER, uid INTEGER, body TEXT);
CREATE TABLE likes (post_id INTEGER, uid INTEGER, UNIQUE (post_id, uid));
INSERT INTO users (handle) VALUES ('ann'), ('bob'), ('cat'), ('dan');
INSERT INTO threads VALUES (1, 'Hello', 1), (2, 'Bugs', 2), (3, 'Quiet', 4);
INSERT INTO posts (tid, uid, body) VALUES (1, 1, 'hi all'), (1, 2, 'hey'), (2, 2, 'crash on save'),
  (2, 3, 'same here'), (2, 1, 'fixed?'), (1, 3, 'welcome');
INSERT INTO likes VALUES (1, 2), (1, 3), (3, 1), (3, 3), (3, 4), (4, 2), (6, 3);
INSERT INTO likes VALUES (5, 2), (1, 3);
-- threads with starter and post count
SELECT title, handle, (SELECT count(*) FROM posts p WHERE p.tid = t.tid) AS n
  FROM threads t JOIN users ON uid = starter ORDER BY n DESC, title;
-- most liked post per thread
SELECT t.title, p.body FROM threads t JOIN posts p USING (tid)
  WHERE (SELECT count(*) FROM likes WHERE post_id = p.id) =
        (SELECT max(c) FROM (SELECT count(*) AS c FROM likes GROUP BY post_id))
  ORDER BY t.title;
-- likes received by each user, zero included
SELECT handle, count(post_id) FROM users u LEFT JOIN posts ON posts.uid = u.uid
  LEFT JOIN likes ON post_id = posts.id GROUP BY u.uid ORDER BY handle;
-- users who liked their own post
SELECT handle FROM users u WHERE EXISTS (SELECT 1 FROM posts JOIN likes ON post_id = id
  WHERE posts.uid = u.uid AND likes.uid = u.uid) ORDER BY handle;
-- the threads each user posted in
SELECT handle, (SELECT group_concat(DISTINCT tid ORDER BY tid) FROM posts WHERE posts.uid = users.uid) FROM users ORDER BY uid;
-- threads with no posts
SELECT title FROM threads LEFT JOIN posts USING (tid) WHERE posts.id IS NULL;
DELETE FROM likes WHERE post_id IN (SELECT id FROM posts WHERE uid = (SELECT uid FROM users WHERE handle = 'bob'));
SELECT post_id, uid FROM likes ORDER BY post_id, uid;
SELECT uid FROM posts JOIN likes ON post_id = id;
SELECT handle FROM users WHERE uid IN (SELECT uid, post_id FROM likes);
SELECT * FROM threads JOIN posts USING (tid) JOIN users USING (uid) WHERE handle = 'cat' ORDER BY id;
