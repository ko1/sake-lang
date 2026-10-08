-- A condition on the right table in ON keeps the unmatched left rows; in WHERE it drops them.
CREATE TABLE users (id INTEGER, name TEXT);
CREATE TABLE logins (user_id INTEGER, day INTEGER);
INSERT INTO users VALUES (1, 'ann'), (2, 'bob'), (3, 'cid');
INSERT INTO logins VALUES (1, 5), (1, 9), (2, 3);
SELECT name, day FROM users LEFT JOIN logins ON user_id = id AND day > 4 ORDER BY name, day;
SELECT name, day FROM users LEFT JOIN logins ON user_id = id WHERE day > 4 ORDER BY name, day;
SELECT name, day FROM users LEFT JOIN logins ON user_id = id WHERE day > 4 OR day IS NULL ORDER BY name, day;
SELECT name FROM users LEFT JOIN logins ON user_id = id AND name = 'bob' ORDER BY name;
