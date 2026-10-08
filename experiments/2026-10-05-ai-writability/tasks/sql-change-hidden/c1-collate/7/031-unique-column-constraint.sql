-- A UNIQUE column compares under its collation, on INSERT and UPDATE.
CREATE TABLE tags (id INTEGER PRIMARY KEY, label TEXT UNIQUE COLLATE NOCASE, slug TEXT COLLATE RTRIM UNIQUE);
INSERT INTO tags (label, slug) VALUES ('News', 'news'), ('Tech', 'tech');
INSERT INTO tags (label, slug) VALUES ('NEWS', 'n2');
INSERT INTO tags (label, slug) VALUES ('Sport', 'tech   ');
INSERT INTO tags (label, slug) VALUES ('Sport', ' tech'), ('Art', 'Tech');
UPDATE tags SET label = 'tech' WHERE id = 1;
UPDATE tags SET label = 'NEWS' WHERE id = 1;
SELECT id, label, slug FROM tags ORDER BY id;
