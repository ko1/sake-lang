-- mixed: the new functions in UPDATE, INSERT ... SELECT, joins and subqueries
CREATE TABLE users (id INTEGER PRIMARY KEY, fname TEXT, lname TEXT, label TEXT UNIQUE);
INSERT INTO users (fname, lname) VALUES ('Mia', 'Ng'), ('Raj', NULL), ('Ola', 'Berg');
UPDATE users SET label = concat_ws('.', lower(fname), lower(lname));
SELECT id, label FROM users ORDER BY id;
UPDATE users SET label = concat('mia', '.', 'ng') WHERE id = 2;
CREATE TABLE codes (uid INTEGER, c INTEGER);
INSERT INTO codes SELECT id, unicode(fname) FROM users;
SELECT u.fname, char(k.c) FROM users u JOIN codes k ON k.uid = u.id ORDER BY u.id;
SELECT fname FROM users WHERE unicode(fname) IN (SELECT c FROM codes WHERE sign(c - 80) = 1) ORDER BY fname;
