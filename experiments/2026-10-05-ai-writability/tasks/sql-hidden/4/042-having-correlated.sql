-- HAVING and result columns of a grouped query using correlated subqueries on the group key.
CREATE TABLE posts (author TEXT, words INTEGER);
CREATE TABLE quota (author TEXT, max_posts INTEGER);
INSERT INTO posts VALUES ('ann', 100), ('ann', 300), ('ann', 50), ('bob', 400), ('cy', 10), ('cy', 20);
INSERT INTO quota VALUES ('ann', 2), ('bob', 5), ('cy', 2);
SELECT author, count(*) FROM posts GROUP BY author
  HAVING count(*) > (SELECT max_posts FROM quota WHERE quota.author = posts.author) ORDER BY author;
SELECT author, sum(words), (SELECT max_posts FROM quota q WHERE q.author = posts.author) - count(*) AS left_over
  FROM posts GROUP BY author ORDER BY left_over, author;
SELECT author FROM posts GROUP BY author HAVING max(words) >= (SELECT avg(words) FROM posts) ORDER BY author;
SELECT count(*) FROM posts WHERE words > (SELECT avg(words) FROM posts p2 WHERE p2.author = posts.author);
