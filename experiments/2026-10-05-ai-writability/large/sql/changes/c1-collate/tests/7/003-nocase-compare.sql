-- NOCASE folds A-Z to lower case before comparing; an explicit COLLATE beats a column's collation.
CREATE TABLE users (id INTEGER, login TEXT COLLATE NOCASE, code TEXT);
INSERT INTO users VALUES (1, 'Kim', 'kim'), (2, 'lee', 'LEE'), (3, '_x', '_x'), (4, NULL, 'Max');
SELECT id FROM users WHERE login = 'KIM';
SELECT id FROM users WHERE 'LEE' = login;
SELECT id FROM users WHERE login = code ORDER BY id;
SELECT id FROM users WHERE code = login ORDER BY id;
SELECT id FROM users WHERE code = login COLLATE NOCASE ORDER BY id;
SELECT id FROM users WHERE login < 'b' ORDER BY id;
SELECT id FROM users WHERE login COLLATE BINARY < 'b' ORDER BY id;
SELECT id FROM users WHERE login > 'JOE' ORDER BY id;
SELECT id, login IS 'kim', login IS NOT 'LEE', login != 'KIM' FROM users ORDER BY id;
SELECT id FROM users WHERE login LIKE 'k%' ORDER BY id;
