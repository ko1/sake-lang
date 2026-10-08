-- INSERT, UPDATE and DELETE may use subqueries over other tables.
CREATE TABLE ids (id INTEGER PRIMARY KEY, name TEXT UNIQUE);
CREATE TABLE banned (name TEXT);
INSERT INTO ids VALUES (1, 'ann'), (2, 'bob'), (3, 'cid');
INSERT INTO banned VALUES ('bob'), ('zed');
INSERT INTO ids VALUES ((SELECT count(*) FROM banned) + 10, (SELECT name FROM banned WHERE name > 'x'));
SELECT * FROM ids ORDER BY id;
UPDATE ids SET name = upper(name) WHERE name IN (SELECT name FROM banned);
SELECT * FROM ids ORDER BY id;
UPDATE ids SET name = name || '!' WHERE name NOT IN (SELECT upper(name) FROM banned);
SELECT * FROM ids ORDER BY id;
INSERT INTO ids VALUES ((SELECT count(*) FROM banned), 'dup');
INSERT INTO ids (name) VALUES ((SELECT 'ann!'));
DELETE FROM ids WHERE EXISTS (SELECT 1 FROM banned WHERE name = 'zed') AND id > 10;
SELECT * FROM ids ORDER BY id;
