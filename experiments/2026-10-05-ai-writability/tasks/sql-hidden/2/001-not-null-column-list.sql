CREATE TABLE contacts (fname TEXT NOT NULL, lname TEXT NOT NULL, phone TEXT);
INSERT INTO contacts (lname, fname) VALUES ('Diaz', 'Rosa');
INSERT INTO contacts (fname, phone) VALUES ('Omar', '555');
INSERT INTO contacts (phone) VALUES ('556');
INSERT INTO contacts VALUES ('Lin', NULL, NULL);
INSERT INTO contacts VALUES ('Lin', 'Wu', NULL), ('Kai', nullif('x', 'x'), '1');
INSERT INTO contacts VALUES ('Lin', 'Wu', NULL), ('Kai', 'Mo', '2');
SELECT fname, lname, coalesce(phone, 'n/a') FROM contacts ORDER BY fname;
