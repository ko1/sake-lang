CREATE TABLE users (id INTEGER, email TEXT UNIQUE);
INSERT INTO users VALUES (1, 'a@x.org');
INSERT INTO users VALUES (2, 'b@x.org');
INSERT INTO users VALUES (3, 'a@x.org');
INSERT INTO users VALUES (3, 'A@x.org');
SELECT id, email FROM users ORDER BY id;
UPDATE users SET email = 'b@x.org' WHERE id = 1;
UPDATE users SET email = 'c@x.org' WHERE id = 1;
SELECT id, email FROM users ORDER BY id;
