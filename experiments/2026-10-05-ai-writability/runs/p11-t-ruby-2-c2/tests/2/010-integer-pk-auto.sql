-- an INTEGER PRIMARY KEY without a value gets the largest plus one, or 1
CREATE TABLE items (id INTEGER PRIMARY KEY, name TEXT);
INSERT INTO items (name) VALUES ('pen');
INSERT INTO items (name) VALUES ('ink');
INSERT INTO items VALUES (NULL, 'cap');
INSERT INTO items VALUES (10, 'box');
INSERT INTO items (name) VALUES ('lid');
SELECT id, name FROM items ORDER BY id;
SELECT typeof(id) FROM items WHERE name = 'pen';
