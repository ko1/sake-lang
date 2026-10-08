CREATE TABLE u (id INTEGER, name TEXT);
INSERT INTO u (id, nmae) VALUES (1, 'typo');
INSERT INTO u (ID, Name, Extra) VALUES (1, 'x', 'y');
INSERT INTO U (NAME, Age) VALUES ('x', 3);
INSERT INTO u (name) VALUES ('kept');
SELECT id, name FROM u;
INSERT INTO missing_table (id) VALUES (1);
INSERT INTO missing_table VALUES (1);
