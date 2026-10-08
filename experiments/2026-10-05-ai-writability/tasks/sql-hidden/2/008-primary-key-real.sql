CREATE TABLE rates (r REAL PRIMARY KEY, name TEXT);
INSERT INTO rates VALUES (1, 'one'), (0.5, 'half');
INSERT INTO rates VALUES (1.0, 'uno');
INSERT INTO rates VALUES ('0.5', 'mitad');
INSERT INTO rates (name) VALUES ('none');
INSERT INTO rates VALUES (NULL, 'none');
INSERT INTO rates VALUES (2, 'two');
SELECT r, name FROM rates ORDER BY r DESC;
