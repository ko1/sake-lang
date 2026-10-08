-- a failed INSERT leaves nothing behind, so numbering continues from the stored rows
CREATE TABLE q (id INTEGER PRIMARY KEY, name TEXT NOT NULL);
INSERT INTO q (name) VALUES ('a');
INSERT INTO q (name) VALUES ('b'), (NULL);
INSERT INTO q (name) VALUES ('c'), ('d');
INSERT INTO q VALUES (NULL, 'e'), (3, 'f');
INSERT INTO q VALUES (NULL, 'e'), (9, 'f');
SELECT id, name FROM q ORDER BY id;
