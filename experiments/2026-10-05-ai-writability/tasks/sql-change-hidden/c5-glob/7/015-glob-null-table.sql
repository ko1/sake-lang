CREATE TABLE contacts (id INTEGER PRIMARY KEY, nick TEXT, pat TEXT);
INSERT INTO contacts (nick, pat) VALUES ('zed', 'z*'), (NULL, 'z*'), ('amy', NULL), ('zoe', 'a*');
SELECT id, nick GLOB pat, nick NOT GLOB pat FROM contacts ORDER BY id;
SELECT id FROM contacts WHERE nick GLOB pat ORDER BY id;
SELECT id FROM contacts WHERE nick NOT GLOB pat ORDER BY id;
SELECT count(*) FROM contacts WHERE (nick GLOB 'z*') IS NULL;
