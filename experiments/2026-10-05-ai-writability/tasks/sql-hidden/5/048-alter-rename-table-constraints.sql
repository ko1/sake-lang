-- after RENAME TO, constraints, INTEGER PRIMARY KEY and indexes work under the new name
CREATE TABLE tmp_user (id INTEGER PRIMARY KEY, login TEXT NOT NULL, mail TEXT, UNIQUE (login));
INSERT INTO tmp_user (login, mail) VALUES ('ann', 'a@m'), ('bob', 'b@m');
CREATE UNIQUE INDEX tmp_user_mail ON tmp_user (mail);
ALTER TABLE tmp_user RENAME TO users;
INSERT INTO users (login, mail) VALUES ('cy', 'c@m');
INSERT INTO users (login, mail) VALUES ('ann', 'z@m');
INSERT INTO users (login, mail) VALUES ('dan', 'a@m');
INSERT INTO users (login) VALUES (NULL);
INSERT INTO users VALUES (2, 'eve', 'e@m');
UPDATE users SET mail = 'b@m' WHERE login = 'cy';
SELECT id, login, mail FROM users ORDER BY id;
INSERT INTO tmp_user VALUES (9, 'x', 'x');
CREATE TABLE tmp_user (n INTEGER);
INSERT INTO tmp_user VALUES (1);
SELECT n FROM tmp_user;
