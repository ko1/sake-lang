-- x IN (select) compares as x = e with e the subquery's result expression.
CREATE TABLE allow (who TEXT COLLATE NOCASE, raw TEXT);
CREATE TABLE req (id INTEGER, usr TEXT);
INSERT INTO allow VALUES ('Ana', 'Ana'), ('ben', 'ben');
INSERT INTO req VALUES (1, 'ANA'), (2, 'Ben'), (3, 'cat'), (4, 'ben');
SELECT id FROM req WHERE usr IN (SELECT who FROM allow) ORDER BY id;
SELECT id FROM req WHERE usr IN (SELECT raw FROM allow) ORDER BY id;
SELECT id FROM req WHERE usr IN (SELECT raw COLLATE NOCASE FROM allow) ORDER BY id;
SELECT id FROM req WHERE upper(usr) IN (SELECT who FROM allow) ORDER BY id;
SELECT id FROM req WHERE usr NOT IN (SELECT who FROM allow) ORDER BY id;
