CREATE TABLE posts (author TEXT, likes INTEGER, words INTEGER);
INSERT INTO posts VALUES ('ana', 10, 300), ('ben', 2, 900), ('ana', 7, 100), ('cyd', 25, 50), ('ben', 4, 800);
SELECT author FROM posts GROUP BY author ORDER BY sum(likes) DESC;
SELECT author FROM posts GROUP BY author ORDER BY avg(words), author;
SELECT author, count(*) FROM posts GROUP BY author ORDER BY max(likes) - min(likes), author;
SELECT author FROM posts GROUP BY author ORDER BY group_concat(likes, '' ORDER BY likes) DESC;
SELECT author FROM posts GROUP BY author HAVING count(*) > 1 ORDER BY total(words) LIMIT 1;
