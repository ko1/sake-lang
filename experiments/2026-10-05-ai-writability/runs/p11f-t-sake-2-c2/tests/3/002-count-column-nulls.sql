CREATE TABLE contacts (id INTEGER PRIMARY KEY, name TEXT, email TEXT, phone TEXT);
INSERT INTO contacts (name, email, phone) VALUES ('ann', 'ann@x.org', NULL), ('bob', NULL, NULL);
INSERT INTO contacts (name, email, phone) VALUES ('cid', 'cid@x.org', '555'), ('dee', NULL, '556');
SELECT count(*), count(email), count(phone), count(id) FROM contacts;
SELECT count(email || phone) FROM contacts;
SELECT count(NULL), count(1) FROM contacts;
