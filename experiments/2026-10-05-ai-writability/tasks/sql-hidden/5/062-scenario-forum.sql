-- scenario: a forum with threaded replies
CREATE TABLE msg (id INTEGER PRIMARY KEY, reply_to INTEGER, author TEXT NOT NULL, body TEXT);
INSERT INTO msg (reply_to, author, body) VALUES (NULL, 'ann', 'hello'), (1, 'bob', 'hi ann'), (1, 'cy', 'welcome'), (2, 'ann', 'thanks bob'), (4, 'bob', 'np'), (NULL, 'dan', 'news'), (6, 'ann', 'cool');
WITH RECURSIVE thread(id, depth) AS (SELECT id, 0 FROM msg WHERE id = 1 UNION ALL SELECT m.id, t.depth + 1 FROM msg m JOIN thread t ON m.reply_to = t.id)
SELECT t.depth, m.author, m.body FROM thread t JOIN msg m ON m.id = t.id ORDER BY t.depth, m.id;
WITH RECURSIVE root(id, top) AS (SELECT id, id FROM msg WHERE reply_to IS NULL UNION ALL SELECT m.id, r.top FROM msg m JOIN root r ON m.reply_to = r.id)
SELECT top, count(*) FROM root GROUP BY top ORDER BY top;
CREATE VIEW poster AS SELECT author, count(*) AS posts FROM msg GROUP BY author;
SELECT author, posts FROM poster ORDER BY posts DESC, author;
SELECT author FROM msg WHERE reply_to IS NULL INTERSECT SELECT author FROM msg WHERE reply_to IS NOT NULL;
SELECT author FROM msg WHERE reply_to IS NOT NULL EXCEPT SELECT author FROM msg WHERE reply_to IS NULL ORDER BY author;
CREATE UNIQUE INDEX msg_body ON msg (author, body);
INSERT INTO msg (reply_to, author, body) VALUES (3, 'bob', 'np');
INSERT INTO msg (reply_to, author, body) VALUES (3, 'bob', 'ok');
ALTER TABLE msg ADD COLUMN likes INTEGER DEFAULT 0;
UPDATE msg SET likes = likes + 2 WHERE author = 'ann';
UPDATE msg SET likes = likes + 1 WHERE id IN (SELECT reply_to FROM msg);
SELECT id, likes FROM msg WHERE likes > 0 ORDER BY likes DESC, id;
SELECT p.author, p.posts, (SELECT sum(likes) FROM msg WHERE author = p.author) FROM poster p ORDER BY p.author;
DROP INDEX msg_body;
INSERT INTO msg (reply_to, author, body) VALUES (8, 'bob', 'np');
SELECT count(*) FROM msg WHERE body = 'np';
SELECT author, posts FROM poster WHERE author = 'bob';
